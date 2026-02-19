<?php
/**
 * Market Hub API - Verify PIN Reset OTP
 * POST /api/verify-reset-otp.php
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
$email = trim(strtolower($data['email'] ?? ''));
$otp = trim($data['otp'] ?? '');

if (empty($email) || empty($otp)) {
    api_error('Email and OTP are required');
}

// Get user with OTP
$user = db_fetch_one(
    "SELECT id, pin_reset_otp, pin_reset_otp_expires
     FROM users
     WHERE email = ? AND status = 'approved'",
    's',
    [$email]
);

if (!$user) {
    api_error('Invalid email');
}

// Check if OTP exists
if (empty($user['pin_reset_otp'])) {
    api_error('No active PIN reset request found. Please request a new code.');
}

// Check if expired
if (strtotime($user['pin_reset_otp_expires']) < time()) {
    api_error('Reset code has expired. Please request a new one.');
}

// Verify OTP
if ($user['pin_reset_otp'] != $otp) {
    api_error('Invalid reset code. Please check and try again.');
}

// Generate temporary reset token (valid for 10 minutes)
$reset_token = bin2hex(random_bytes(32));
$reset_token_expires = date('Y-m-d H:i:s', strtotime('+10 minutes'));

// Clear OTP and set reset token
$updated = db_query(
    "UPDATE users
     SET pin_reset_token = ?, pin_reset_token_expires = ?, pin_reset_otp = NULL, pin_reset_otp_expires = NULL
     WHERE id = ?",
    'ssi',
    [$reset_token, $reset_token_expires, $user['id']]
);

if (!$updated) {
    api_error('Failed to verify OTP. Please try again.');
}

api_success([
    'reset_token' => $reset_token,
    'user_id' => $user['id']
], 'OTP verified successfully');
