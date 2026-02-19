<?php
/**
 * Market Hub API - Reset PIN with Token
 * POST /api/reset-pin.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

// Ensure JSON response headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$data = get_json_input();
$reset_token = trim($data['reset_token'] ?? '');
$new_pin = trim($data['new_pin'] ?? '');

if (empty($reset_token) || empty($new_pin)) {
    api_error('Reset token and new PIN are required');
}

// Validate PIN format (4 digits)
if (!preg_match('/^\d{4}$/', $new_pin)) {
    api_error('PIN must be 4 digits');
}

// Verify reset token
$user = db_fetch_one(
    "SELECT id, pin_reset_token_expires
     FROM users
     WHERE pin_reset_token = ? AND status = 'approved'",
    's',
    [$reset_token]
);

if (!$user) {
    api_error('Invalid reset token');
}

// Check if expired
if (strtotime($user['pin_reset_token_expires']) < time()) {
    api_error('Reset token has expired. Please start over.');
}

// Hash new PIN
$pin_hash = hash_pin($new_pin);

// Update PIN and clear reset fields
$updated = db_query(
    "UPDATE users
     SET pin_hash = ?,
         pin_reset_otp = NULL,
         pin_reset_otp_expires = NULL,
         pin_reset_token = NULL,
         pin_reset_token_expires = NULL
     WHERE id = ?",
    'si',
    [$pin_hash, $user['id']]
);

if ($updated) {
    api_success([], 'PIN reset successfully');
} else {
    api_error('Failed to reset PIN');
}
