<?php
/**
 * FCM Status & Quick-Fix Tool
 *
 * Visit: https://mehrgrewal.com/markethub/api/fcm_status.php?key=mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC
 *
 * Add &fix=1  to delete the stale token cache (forces re-auth on next notification)
 * Add &test=1 to send a test notification to the first user in the DB
 */

// Show all PHP errors so we can diagnose 500s instead of getting a blank page
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$cron_key = $_GET['key'] ?? '';
if ($cron_key !== 'mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC') {
    http_response_code(403);
    die(json_encode(['error' => 'Unauthorized']));
}

define('ADMIN_PANEL', true);
header('Content-Type: text/plain; charset=utf-8');
require_once __DIR__ . '/config.php';

$lines = [];
$ok = function($msg) use (&$lines) { $lines[] = "✓ $msg"; };
$err = function($msg) use (&$lines) { $lines[] = "✗ $msg"; };
$info = function($msg) use (&$lines) { $lines[] = "  $msg"; };

$lines[] = "=== FCM Status Check (" . date('d-M-Y H:i:s') . " IST) ===\n";

// ── 1. Determine which key will be used ─────────────────────────────
$db_sa_raw = get_setting('firebase_service_account');
$using_db_key = false;

if (!empty($db_sa_raw)) {
    $db_sa = json_decode($db_sa_raw, true);
    if (is_array($db_sa) && !empty($db_sa['project_id']) && !empty($db_sa['private_key'])) {
        $ok("DB key (Admin → Settings → Firebase) is valid JSON");
        $info("Project ID : " . $db_sa['project_id']);
        $info("Key ID     : " . ($db_sa['private_key_id'] ?? 'unknown'));
        $info("Client     : " . ($db_sa['client_email'] ?? 'unknown'));
        $using_db_key = true;
        $sa_json = $db_sa_raw;
        $sa = $db_sa;
    } else {
        $err("DB key is set but INVALID JSON — will fall back to hardcoded key");
    }
}

if (!$using_db_key) {
    $info("No valid DB key — using hardcoded key in config.php");
    // Parse the hardcoded key (it's the fallback in send_push_notification)
    $sa_json_start = strpos(file_get_contents(__FILE__), '"type": "service_account"');
    // Re-call send_push_notification logic: we need to get the hardcoded SA
    // Easiest: trigger it via the existing function but intercept with a dummy token
    // Instead, just show what the DB has and whether auth works
    $sa = null;
    $sa_json = null;
}

// ── 2. Token cache status ────────────────────────────────────────────
$lines[] = "";
$lines[] = "--- Token Cache ---";
$cache_files = glob(__DIR__ . '/.fcm_token_*.json');
if (empty($cache_files)) {
    $info("No token cache file found (will fetch fresh token on next notification)");
} else {
    foreach ($cache_files as $cf) {
        $cached = json_decode(file_get_contents($cf), true);
        $key_part = basename($cf, '.json');
        if (!empty($cached['expires_at'])) {
            $remaining = $cached['expires_at'] - time();
            if ($remaining > 0) {
                $ok("Cache: $key_part — expires in " . round($remaining / 60) . " min");
            } else {
                $err("Cache: $key_part — EXPIRED (will auto-refresh)");
            }
        } else {
            $err("Cache: $key_part — corrupt, no expires_at");
        }
    }
}

// ── 3. Clear cache if requested ─────────────────────────────────────
if (isset($_GET['fix']) && $_GET['fix'] === '1') {
    $lines[] = "";
    $lines[] = "--- Clearing Token Cache (&fix=1) ---";
    $deleted = 0;
    foreach (glob(__DIR__ . '/.fcm_token_*.json') as $cf) {
        @unlink($cf);
        $deleted++;
    }
    $ok("Deleted $deleted cache file(s). Next notification will fetch a fresh token.");
}

// ── 4. Try to get an access token ───────────────────────────────────
$lines[] = "";
$lines[] = "--- Auth Test ---";

// get_active_service_account() returns DB key if valid, else hardcoded fallback
$active_sa = get_active_service_account();
$info("Key ID in use : " . ($active_sa['private_key_id'] ?? 'unknown'));
$info("Client email  : " . ($active_sa['client_email'] ?? 'unknown'));

$test_token = get_firebase_access_token($active_sa);
if ($test_token) {
    $ok("Access token obtained successfully!");
    $info("Token preview : " . substr($test_token, 0, 20) . "...");
} else {
    $err("FAILED to get access token — key has been revoked or deleted from GCP Console");
    $err("Fix: Firebase Console → Project Settings → Service Accounts");
    $err("     → Generate new private key → paste JSON in Admin → Settings → Firebase → Save");
}

// ── 5. Send test notification if requested ──────────────────────────
if (isset($_GET['test']) && $_GET['test'] === '1') {
    $lines[] = "";
    $lines[] = "--- Test Notification (&test=1) ---";
    $user = db_fetch_one(
        "SELECT id, fcm_token FROM users WHERE fcm_token IS NOT NULL AND fcm_token != '' AND status = 'approved' LIMIT 1"
    );
    if (!$user) {
        $err("No approved users with FCM tokens found in DB");
    } else {
        $info("Sending test to user ID " . $user['id']);
        $result = send_push_notification(
            $user['fcm_token'],
            'MH FCM Test',
            'If you see this, FCM is working! (' . date('H:i:s') . ')',
            ['type' => 'price_alert']
        );
        if (!empty($result['name'])) {
            $ok("Test notification sent! Message: " . $result['name']);
        } elseif (isset($result['error'])) {
            $err("FCM rejected: " . json_encode($result['error']));
        } else {
            $err("Unexpected result: " . json_encode($result));
        }
    }
}

// ── 6. DB user/token summary ─────────────────────────────────────────
$lines[] = "";
$lines[] = "--- User FCM Token Summary ---";
$total  = db_fetch_one("SELECT COUNT(*) as c FROM users WHERE status = 'approved'");
$with_t = db_fetch_one("SELECT COUNT(*) as c FROM users WHERE status = 'approved' AND fcm_token IS NOT NULL AND fcm_token != ''");
$info("Approved users total    : " . ($total['c'] ?? 0));
$info("With FCM token (active) : " . ($with_t['c'] ?? 0));

// Show users WITH tokens so admin can see if their own account is registered
$token_users = db_fetch_all(
    "SELECT id, full_name, phone, fcm_token FROM users WHERE status = 'approved' AND fcm_token IS NOT NULL AND fcm_token != '' ORDER BY id DESC LIMIT 30"
);
if (!empty($token_users)) {
    $lines[] = "";
    $lines[] = "  Users with active FCM tokens (latest 30):";
    foreach ($token_users as $u) {
        $lines[] = "    ID {$u['id']} — {$u['full_name']} ({$u['phone']}) — token: " . substr($u['fcm_token'], 0, 20) . "...";
    }
}

$lines[] = "";
$lines[] = "=== Quick Fix Guide ===";
$lines[] = "If notifications stopped:";
$lines[] = "1. Visit this URL with &fix=1 to clear stale token cache";
$lines[] = "2. If still broken, go to Firebase Console → Project Settings → Service Accounts";
$lines[] = "   → Generate new private key → copy entire JSON";
$lines[] = "3. Paste it in your Admin Panel → Settings → Firebase Service Account JSON → Save";
$lines[] = "   (DO NOT delete old keys from GCP Console unless you have already pasted the new one)";
$lines[] = "4. Visit this URL with &fix=1&test=1 to verify";

echo implode("\n", $lines) . "\n";
