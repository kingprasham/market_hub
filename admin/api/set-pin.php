<?php
/**
 * Market Hub API - Set PIN
 * POST /api/set-pin.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$data = get_json_input();
$user_id = intval($data['user_id'] ?? 0);
$pin = trim($data['pin'] ?? '');

if (!$user_id || empty($pin)) {
    api_error('User ID and PIN are required');
}

if (strlen($pin) !== 4 || !ctype_digit($pin)) {
    api_error('PIN must be 4 digits');
}

// Get user
$user = db_fetch_one("SELECT * FROM users WHERE id = ?", 'i', [$user_id]);

if (!$user) {
    api_error('User not found');
}

if (!$user['email_verified']) {
    api_error('Please verify your email first');
}

// Hash and save PIN
$pin_hash = hash_pin($pin);
db_query(
    "UPDATE users SET pin_hash = ? WHERE id = ?",
    'si',
    [$pin_hash, $user_id]
);

api_success([
    'user_id' => $user_id,
    'status' => $user['status']
], 'PIN set successfully');
