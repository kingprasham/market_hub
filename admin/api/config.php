<?php
/**
 * Market Hub API - Configuration
 */

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

// Error handling
set_error_handler(function($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

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
    $parts = explode(':', base64_decode($token));
    if (count($parts) !== 2) {
        api_error('Invalid token', 401);
    }
    
    $user_id = intval($parts[0]);
    $device_token = $parts[1];
    
    $user = db_fetch_one(
        "SELECT * FROM users WHERE id = ? AND device_token = ? AND status = 'approved'",
        'is',
        [$user_id, $device_token]
    );
    
    if (!$user) {
        api_error('Invalid or expired session', 401);
    }
    
    // Check plan expiry
    if ($user['plan_expires_at'] && strtotime($user['plan_expires_at']) < time()) {
        api_error('Your subscription has expired', 403);
    }
    
    return $user;
}

/**
 * Send push notification via Firebase Cloud Messaging
 * Supports both Legacy API (server key) and V1 API (service account)
 */
function send_push_notification($device_token, $title, $body, $data = []) {
    // Try V1 API first (service account JSON)
    $service_account = get_setting('firebase_service_account');
    
    // Hardcoded fallback if DB setting is empty
    if (empty($service_account)) {
        $service_account = '{
  "type": "service_account",
  "project_id": "market-hub-58dca",
  "private_key_id": "03722d3d8672c046d78eee11ea116a213baacc1a",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQD16C/dE7BLvqQ4\\nT03EefA99vz1xugEzoprj3jtaq/ZOxQMl6eSp1lyL+1S36tN8678gcf7YJy/aKtJ\\nDjIVa4xtHQERBl4O5sZKCheRLa6lU/0hKRIIuP/NuoxMKJlGucHi+NDeLBegTFob\\nNf7KNfhG94kxz6VK0zxqiX2fQdgzaLHIQebzFIKuts5d5J1KgMcvc4AEJYNPQ+88\\nr7XYwcSVRtmKuhFWy8CzjiSZ/zscLWnv1NPnA80cBKQSVB0sEeRnIZMTO3gyEQ66\\nTGweqm6hwgE+3hAuuvusK6HBxw3on0vV7zli0kTnjij1AsMQiASjOFes4BPXrxvd\\nd1Q+ANOJAgMBAAECggEAP4e2geu5wr/khmW6pjWIo0Ghtc+nFsLTkRlWeSP0fW9d\\nbSlrEiDpI26NZjlB9RgtT7Ap3eBmbq8YfX3M46rO80uogGEAQOJPPUahMxE1yyHJ\\nRl1petZsxBZbc7uTaenI1R5KO/PxQKkpKFmJU22hEJiYGcXXIt8y/yU5TsFAnXr/\\nuaMPKJIN4OuWPTsH4e1Mn2En6G6u02SOWWExVpdhzRE+GpgL5vmdoGT0MLu7Ov/C\\n8qKUKTkZTEpKCORIVMKo/hQNHxnOrm+3ohlVckPGYRS4lFwDiJc3lmcznT6DG1kq\\n4E1gvPTMIt2i4An7Z3hAwG+alpujmbL5UV02SbyeDwKBgQD8wU98NTKJesswQDF+\\nTrUiO0etkw8k1NBl8tmH1tKkFV71twR0TA9Nd44iQHMR39XiakmOAQhLpTw3tvWa\\n8nMA95lsnia+AivQQxEhqtmeSZ9s8JwOCpFDm4iqM2XrZFqcZPK6e49J1j0YzStH\\n3BSZkzZmf2WwKHrQ4m4FhTRowwKBgQD5EF6rfXY5LML++8Jj6FdXrn7DvngH+iOt\\nfG8qY796i8oOXH7ZixRwHpsk4WZNQUlDw5pGYKzeGreqacYD3mNjbaQmIzVnhCTt\\nZX00ZhVnA8Xewv0Kj7ansEBbEz4HboeOexMsuuRnwtNv4jeqmTTbXoECEh2O/WMp\\n8kgVF/5twwKBgDJWXXojLhlrNyQ45KJ/Elvq6m+LJizzpT1ojCIdin3bM7pD5MM0\\nkqee89OmekRJC9O3z0ZUtk46bi+6ZFejiXvb09Zp+NVGoWsssDDAUe7QQsvzb2Ds\\ngdmxFBqxec7Tgag8AotZKERQQoK5+bCqCAA97Uuke6AFr9ACCF9ZFAL5AoGARCXi\\ngXHWw1YoFLS2P7f3DhrEvLKFDUm4MWP21tZsMg/FvaA5ZTTU5si5EqJJ56GRdmUy\\n9UbGhg8xagN/FtfmwfHiFD1WA3j40awPUiMMgB9cKNOZgSZJiCCFu2XMdyQbGzU5\\nzedlT67TQ63WJWu+Nrfo/LQQOmvCkluktYDXMRkCgYA7dWi5WUWs2RMEHAAbaLrO\\n7E/Ruz3rkbYsvj1nKU2YaaiBxupFFG0fFg1SgdcdnjNQTsuH5sfGnSzatGtJMys4\\nxSD8Yzv8UUsPSyB70U33mB6LVPsWlQws5McWNfW7F6WL1VTOOnUeoUECBMFDLIYz\\n0aCA0WZEPtDSB3zXax8nnQ==\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@market-hub-58dca.iam.gserviceaccount.com",
  "client_id": "112989263646484850552",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40market-hub-58dca.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}';
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
 */
function send_fcm_v1($token, $title, $body, $data, $service_account_json) {
    $service_account = json_decode($service_account_json, true);
    if (!$service_account) return false;
    
    $project_id = $service_account['project_id'] ?? '';
    if (empty($project_id)) return false;
    
    // Get access token from service account
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
    
    // Add data if present, ensuring all values are strings
    if (!empty($data)) {
        // FCM V1 requires all data values to be strings
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
    curl_close($ch);
    
    return json_decode($response, true);
}

/**
 * Get Firebase access token from service account
 */
function get_firebase_access_token($service_account) {
    $jwt_header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    
    $now = time();
    $jwt_claim = base64_encode(json_encode([
        'iss' => $service_account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ]));
    
    $signature_input = $jwt_header . '.' . $jwt_claim;
    $private_key = $service_account['private_key'];
    
    openssl_sign($signature_input, $signature, $private_key, 'SHA256');
    $jwt = $signature_input . '.' . base64_encode($signature);
    
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
    curl_close($ch);
    
    return $response['access_token'] ?? null;
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
            
            if ($error_code === 'NOT_FOUND' || $error_code === 'UNREGISTERED' || $error_code === 'INVALID_ARGUMENT') {
                // Token is stale — user uninstalled app or token expired
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
            }
        } else {
            $failed++;
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
        'news' => 'New News',
        'hindi_news' => 'नई खबर',
        'circular' => 'New Circular',
        'home_update' => 'New Update'
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

