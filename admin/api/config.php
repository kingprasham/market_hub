<?php
/**
 * Market Hub API - Configuration
 */

// Set timezone for consistent timing across app and dashboard
date_default_timezone_set('Asia/Kolkata');

// Only set API headers when this file is used for API calls, not when included from admin pages
if (!defined('ADMIN_PANEL')) {
    // Allow CORS for mobile app
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Content-Type: application/json; charset=utf-8');

    // Handle preflight requests
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit;
    }
}

// Database connection
require_once __DIR__ . '/../config/database.php';

// Include utility functions (generate_otp, etc.) - only if not already loaded via admin pages
if (!function_exists('generate_otp')) {
    require_once __DIR__ . '/../includes/functions.php';
}

// Error handling: only convert errors to exceptions in API context, not admin UI pages
if (!defined('ADMIN_PANEL')) {
    set_error_handler(function($severity, $message, $file, $line) {
        throw new ErrorException($message, 0, $severity, $file, $line);
    });
}

/**
 * Send JSON response
 */
function api_response($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Send error response
 */
function api_error($message, $status = 400) {
    api_response(['success' => false, 'error' => $message], $status);
}

/**
 * Send success response
 */
function api_success($data = [], $message = 'Success') {
    api_response(array_merge(['success' => true, 'message' => $message], $data));
}

/**
 * Get POST JSON data
 */
function get_json_input() {
    $input = file_get_contents('php://input');
    return json_decode($input, true) ?? [];
}

/**
 * Get setting value
 */
function get_setting($key, $default = '') {
    $row = db_fetch_one("SELECT setting_value FROM settings WHERE setting_key = ?", 's', [$key]);
    return $row ? $row['setting_value'] : $default;
}

/**
 * Check if user plan has access to content
 */
function user_has_access($user_plan_id, $target_plans_json) {
    if (empty($target_plans_json)) return true;
    
    $targets = json_decode($target_plans_json, true);
    if (!is_array($targets)) return true;
    if (in_array('all', $targets)) return true;
    
    return in_array($user_plan_id, $targets);
}

/**
 * Verify user authentication token
 */
function verify_auth() {
    // Try to get Authorization header from multiple sources
    $token = '';

    // Method 1: getallheaders()
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        $token = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }

    // Method 2: $_SERVER (fallback for nginx/FastCGI)
    if (empty($token)) {
        $token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    }

    // Method 3: apache_request_headers()
    if (empty($token) && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $token = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }

    // Extract Bearer token
    if (preg_match('/Bearer\s+(.*)$/i', $token, $matches)) {
        $token = $matches[1];
    }

    if (empty($token)) {
        api_error('Authentication required', 401);
    }
    
    // Verify token (user_id:device_token)
    $decoded = base64_decode($token);
    $parts = explode(':', $decoded);
    if (count($parts) !== 2) {
        error_log("Auth Error: Malformed token parts (count=" . count($parts) . ")");
        api_error('Invalid token', 401);
    }
    
    $user_id = intval($parts[0]);
    $device_token = $parts[1];
    
    // Verify in database
    $user = db_fetch_one(
        "SELECT * FROM users WHERE id = ? AND status = 'approved'",
        'i',
        [$user_id]
    );
    
    if (!$user) {
        error_log("Auth Error: User ID $user_id not found or not approved");
        api_error('Invalid or expired session', 401);
    }

    // Verify device token with detailed mismatch check
    if ($user['device_token'] !== $device_token) {
        $db_token_len = strlen($user['device_token']);
        $sent_token_len = strlen($device_token);
        
        error_log("Auth Error: Token mismatch for User ID $user_id. DB Len: $db_token_len, Sent Len: $sent_token_len");
        
        // Truncation detection
        if ($db_token_len == 255 && $sent_token_len > 255) {
            error_log("Auth Error: TRUNCATION DETECTED for User ID $user_id. DB token is exactly 255 chars.");
        }
        
        api_error('Invalid session (token mismatch)', 401);
    }
    
    // Check plan expiry
    if ($user['plan_expires_at'] && strtotime($user['plan_expires_at']) < time()) {
        api_error('Your subscription has expired', 403);
    }
    
    return $user;
}

/**
 * Returns the fallback service-account JSON string loaded from
 * `fcm_service_account.local.json` (gitignored so the credential never
 * lands in version control). Production pulls the real account from the
 * DB setting `firebase_service_account`; this file is only a local
 * fallback when the DB setting is missing or invalid.
 */
function get_hardcoded_service_account_json() {
    $path = __DIR__ . '/fcm_service_account.local.json';
    if (!is_readable($path)) return '';
    $raw = file_get_contents($path);
    return $raw !== false ? $raw : '';
}

/**
 * Return the active service account array (DB key takes priority over hardcoded).
 * Used by fcm_status.php to test auth without making a dummy FCM call.
 */
function get_active_service_account() {
    $db_raw = get_setting('firebase_service_account');
    if (!empty($db_raw)) {
        $sa = json_decode($db_raw, true);
        if (is_array($sa) && !empty($sa['project_id']) && !empty($sa['private_key'])) {
            return $sa;
        }
    }
    $fallback = get_hardcoded_service_account_json();
    return !empty($fallback) ? json_decode($fallback, true) : null;
}

/**
 * Send push notification via Firebase Cloud Messaging
 * Supports both Legacy API (server key) and V1 API (service account)
 */
function send_push_notification($device_token, $title, $body, $data = []) {
    // Try V1 API first (service account JSON)
    $service_account = get_setting('firebase_service_account');

    // Validate DB setting is real JSON with required fields before trusting it
    if (!empty($service_account)) {
        $sa_test = json_decode($service_account, true);
        if (!is_array($sa_test) || empty($sa_test['project_id']) || empty($sa_test['private_key'])) {
            error_log("FCM: DB firebase_service_account is non-empty but invalid JSON/missing fields — falling back to hardcoded key");
            $service_account = '';
        }
    }

    // Hardcoded fallback if DB setting is empty or invalid
    if (empty($service_account)) {
        $service_account = get_hardcoded_service_account_json();
    }

    if (!empty($service_account)) {
        return send_fcm_v1($device_token, $title, $body, $data, $service_account);
    }
    
    // Fallback to Legacy API (server key)
    $server_key = get_setting('firebase_server_key');
    if (!empty($server_key)) {
        return send_fcm_legacy($device_token, $title, $body, $data, $server_key);
    }
    
    return false;
}

/**
 * Send via FCM V1 API (recommended)
 * $retry: internal flag — set false on the retry attempt to prevent infinite loops
 */
function send_fcm_v1($token, $title, $body, $data, $service_account_json, $retry = true) {
    $service_account = json_decode($service_account_json, true);
    if (!$service_account) return false;

    $project_id = $service_account['project_id'] ?? '';
    if (empty($project_id)) return false;

    // Get access token (served from cache when possible)
    $access_token = get_firebase_access_token($service_account);
    if (!$access_token) return false;

    $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";

    // Prepare message payload
    $message_payload = [
        'token' => $token,
        'notification' => [
            'title' => $title,
            'body' => $body
        ],
        'android' => [
            'priority' => 'high',
            'notification' => [
                'sound' => 'default'
            ]
        ]
    ];

    // FCM V1 requires all data values to be strings
    if (!empty($data)) {
        $string_data = [];
        foreach ($data as $key => $value) {
            $string_data[$key] = strval($value);
        }
        $message_payload['data'] = $string_data;
    }

    $message = ['message' => $message_payload];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $access_token,
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($message),
        CURLOPT_RETURNTRANSFER => true
    ]);

    $response = curl_exec($ch);
    $curl_error = curl_error($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    // 401 = the cached access token was rejected (key was rotated/revoked while
    // the token was still in our cache). Clear the cache and retry once with a
    // fresh token so the NEXT call in the same batch succeeds immediately.
    if ($http_code === 401 && $retry) {
        $key_id = preg_replace('/[^a-z0-9]/i', '', $service_account['private_key_id'] ?? 'default');
        $cache_file = __DIR__ . '/.fcm_token_' . $key_id . '.json';
        @unlink($cache_file);
        error_log("FCM V1: got 401, cleared token cache, retrying once...");
        return send_fcm_v1($token, $title, $body, $data, $service_account_json, false);
    }

    $result = json_decode($response, true);

    if ($http_code !== 200) {
        error_log("FCM V1 send failed (HTTP $http_code): " . substr($response, 0, 500));
    }
    if (!empty($curl_error)) {
        error_log("FCM V1 curl error: $curl_error");
    }

    return $result;
}

/**
 * Base64url encode (JWT-safe: no +, /, or = padding)
 */
function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Get Firebase access token from service account.
 *
 * Caches the access token on disk for ~58 minutes so that a batch of 50+
 * notifications issues only ONE JWT sign + ONE OAuth request per hour instead
 * of one per user. This was causing Google to flag the service account as
 * abusive and respond with invalid_grant, stopping all notifications.
 */
function get_firebase_access_token($service_account) {
    // Cache file is keyed to the private_key_id so that rotating to a new key
    // automatically bypasses the old token without manual cleanup.
    $key_id = preg_replace('/[^a-z0-9]/i', '', $service_account['private_key_id'] ?? 'default');
    $cache_file = __DIR__ . '/.fcm_token_' . $key_id . '.json';

    // Return cached token if it's still valid (with a 2-min buffer)
    if (file_exists($cache_file)) {
        $cached = json_decode(file_get_contents($cache_file), true);
        if (!empty($cached['access_token']) && !empty($cached['expires_at'])) {
            if ($cached['expires_at'] > time() + 120) {
                return $cached['access_token'];
            }
        }
    }

    // Build and sign a JWT
    $jwt_header = base64url_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));

    $now = time();
    $jwt_claim = base64url_encode(json_encode([
        'iss' => $service_account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ]));

    $signature_input = $jwt_header . '.' . $jwt_claim;
    $private_key = $service_account['private_key'];

    // Normalize private key: convert literal \n sequences to real newlines if needed
    if (strpos($private_key, "\\n") !== false && strpos($private_key, "\n") === false) {
        $private_key = str_replace("\\n", "\n", $private_key);
    }

    $sign_ok = openssl_sign($signature_input, $signature, $private_key, 'SHA256');
    if (!$sign_ok) {
        $openssl_errors = [];
        while ($err = openssl_error_string()) {
            $openssl_errors[] = $err;
        }
        error_log("FCM Auth: openssl_sign() FAILED. OpenSSL errors: " . implode('; ', $openssl_errors));
        return null;
    }
    $jwt = $signature_input . '.' . base64url_encode($signature);

    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt
        ]),
        CURLOPT_RETURNTRANSFER => true
    ]);

    $response = json_decode(curl_exec($ch), true);
    $curl_error = curl_error($ch);
    curl_close($ch);

    if (!empty($curl_error)) {
        error_log("FCM Auth curl error: $curl_error");
        return null;
    }

    if (isset($response['error'])) {
        // Delete stale cache on auth failure so the next attempt retries cleanly
        @unlink($cache_file);
        error_log("FCM Auth error: " . json_encode($response['error']));
        return null;
    }

    $access_token = $response['access_token'] ?? null;
    if ($access_token) {
        // Cache for 58 minutes (tokens are valid 60 min; 2-min buffer already handled above)
        file_put_contents($cache_file, json_encode([
            'access_token' => $access_token,
            'expires_at'   => time() + 3480
        ]));
    }

    return $access_token;
}

/**
 * Send via FCM Legacy API (deprecated but still works)
 */
function send_fcm_legacy($token, $title, $body, $data, $server_key) {
    $payload = [
        'to' => $token,
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default'
        ],
        'data' => $data
    ];
    
    $ch = curl_init('https://fcm.googleapis.com/fcm/send');
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: key=' . $server_key,
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_RETURNTRANSFER => true
    ]);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    return json_decode($response, true);
}

// Note: generate_otp(), hash_pin(), verify_pin() are defined in includes/functions.php
// Do not redeclare them here

/**
 * Send push notification to all users with FCM tokens
 * @param string $title Notification title
 * @param string $body Notification body
 * @param array $data Additional data payload
 * @param array|null $target_plans If set, only send to users with these plan IDs
 * @return array Results with success/failure counts
 */
function send_push_to_all($title, $body, $data = [], $target_plans = null) {
    // Get all users with FCM tokens
    $query = "SELECT id, fcm_token, plan_id FROM users WHERE fcm_token IS NOT NULL AND fcm_token != '' AND status = 'approved'";
    $users = db_fetch_all($query);
    
    if (empty($users)) {
        return ['sent' => 0, 'failed' => 0, 'total' => 0];
    }
    
    $sent = 0;
    $failed = 0;
    $cleaned = 0;
    $processed_tokens = []; // Track tokens to prevent duplicates for multiple accounts on same device
    
    foreach ($users as $user) {
        $token = $user['fcm_token'];
        
        // Skip if we already sent to this device token in this batch
        if (in_array($token, $processed_tokens)) {
            continue;
        }
        
        // Check plan targeting if specified
        if ($target_plans !== null && !empty($target_plans)) {
            if (!in_array('all', $target_plans) && !in_array($user['plan_id'], $target_plans)) {
                continue; // Skip this user
            }
        }
        
        $processed_tokens[] = $token;
        $result = send_push_notification($token, $title, $body, $data);
        
        if ($result) {
            // Check for stale/invalid token errors from FCM
            $error_code = '';
            if (isset($result['error'])) {
                $error_code = isset($result['error']['status']) ? $result['error']['status'] : '';
            }
            
            if ($error_code === 'NOT_FOUND' || $error_code === 'UNREGISTERED') {
                // Token is stale — user uninstalled app or FCM token expired
                // NOTE: do NOT include INVALID_ARGUMENT here — that means the request
                // payload was malformed (e.g. auth failure), not that the token is bad.
                // Deleting tokens on INVALID_ARGUMENT wiped 26 valid tokens on 01-Apr-2026.
                db_query(
                    "UPDATE users SET fcm_token = NULL WHERE id = ?",
                    'i',
                    [$user['id']]
                );
                $cleaned++;
                $failed++;
                error_log("Cleaned stale FCM token for user ID: {$user['id']}");
            } elseif (isset($result['name'])) {
                // FCM V1 returns 'name' on success
                $sent++;
            } else {
                $failed++;
                // Log unexpected FCM response for diagnostics
                error_log("FCM send_push_to_all: unexpected response for user {$user['id']}: " . json_encode($result));
            }
        } else {
            $failed++;
            // $result is false — send_push_notification returned false (auth failure or curl error)
            // The specific error is already logged in send_fcm_v1 / get_firebase_access_token
        }
    }
    
    if ($cleaned > 0) {
        error_log("FCM: Cleaned $cleaned stale tokens this batch");
    }
    
    return ['sent' => $sent, 'failed' => $failed, 'cleaned' => $cleaned, 'total' => count($users)];
}

/**
 * Send notification for new content (news, circulars, etc.)
 * @param string $type Content type: 'news', 'hindi_news', 'circular', 'home_update'
 * @param string $title Content title
 * @param int $content_id Content ID
 * @param array|null $target_plans Target plan IDs
 */
function send_content_notification($type, $title, $content_id, $target_plans = null) {
    $type_labels = [
        'news' => 'MH News',
        'hindi_news' => 'MH Hindi News',
        'circular' => 'MH Circular Update',
        'home_update' => 'MH Alert'
    ];
    
    $notification_title = $type_labels[$type] ?? 'New Content';
    $notification_body = $title;
    
    $data = [
        'type' => $type,
        'content_id' => strval($content_id),
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
    ];
    
    return send_push_to_all($notification_title, $notification_body, $data, $target_plans);
}

/**
 * Send notification to specific user by ID
 */
function send_user_notification($user_id, $title, $body, $data = []) {
    $user = db_fetch_one("SELECT fcm_token FROM users WHERE id = ?", 'i', [$user_id]);
    
    if ($user && !empty($user['fcm_token'])) {
        return send_push_notification($user['fcm_token'], $title, $body, $data);
    }
    return false;
}
?>
