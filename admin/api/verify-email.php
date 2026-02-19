<?php
/**
 * Market Hub API - Email Verification
 * POST /api/verify-email.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$data = get_json_input();
$user_id = intval($data['user_id'] ?? 0);
$otp = trim($data['otp'] ?? '');

if (!$user_id || empty($otp)) {
    api_error('User ID and OTP are required');
}

// Get user
$user = db_fetch_one(
    "SELECT * FROM users WHERE id = ? AND status = 'pending'",
    'i',
    [$user_id]
);

if (!$user) {
    api_error('Invalid user or already verified');
}

// Check OTP
if ($user['email_otp'] !== $otp) {
    api_error('Invalid OTP');
}

// Check OTP expiry
if (strtotime($user['otp_expires_at']) < time()) {
    api_error('OTP has expired. Please request a new one.');
}

// Mark email as verified
db_query(
    "UPDATE users SET email_verified = 1, email_otp = NULL, otp_expires_at = NULL WHERE id = ?",
    'i',
    [$user_id]
);

api_success([
    'user_id' => $user_id,
    'email_verified' => true
], 'Email verified successfully');
