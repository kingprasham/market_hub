<?php
/**
 * Market Hub API - Request PIN Reset
 * POST /api/forgot-pin.php
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

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    api_error('Valid email is required');
}

// Check if user exists
$user = db_fetch_one("SELECT id, full_name, status, pin_reset_otp, pin_reset_otp_expires FROM users WHERE email = ?", 's', [$email]);

if (!$user) {
    // Security: Don't reveal if email exists
    api_success(['email' => $email], 'If this email is registered, you will receive a PIN reset code.');
}

if ($user['status'] !== 'approved') {
    api_error('Your account is not approved yet');
}

// Check if valid OTP already exists (prevent race conditions)
$current_time = time();
$otp = null;
$otp_expires = null;

if (!empty($user['pin_reset_otp']) && !empty($user['pin_reset_otp_expires'])) {
    $expiry_time = strtotime($user['pin_reset_otp_expires']);
    if ($expiry_time > $current_time) {
        // Reuse existing valid OTP
        $otp = $user['pin_reset_otp'];
        $otp_expires = $user['pin_reset_otp_expires'];
    }
}

if (!$otp) {
    // Generate new 6-digit OTP
    $otp = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
    $otp_expires = date('Y-m-d H:i:s', strtotime('+15 minutes'));

    // Update user with reset OTP
    $updated = db_query(
        "UPDATE users SET pin_reset_otp = ?, pin_reset_otp_expires = ? WHERE id = ?",
        'ssi',
        [$otp, $otp_expires, $user['id']]
    );

    if (!$updated) {
        api_error('Failed to generate reset code. Please try again.');
    }
}

// Send OTP email
$email_subject = "Market Hub - Your PIN Reset Code";
$email_body = "
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
</head>
<body style='font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;'>
    <div style='max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px;'>
        <h2 style='color: #333; margin-bottom: 20px;'>PIN Reset Request</h2>
        <p>Hello {$user['full_name']},</p>
        <p>You requested to reset your PIN. Use the code below to proceed:</p>
        <div style='background: #f8f9fa; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;'>
            <h1 style='color: #FF6B35; font-size: 36px; letter-spacing: 8px; margin: 0;'>$otp</h1>
        </div>
        <p><strong>This code expires in 15 minutes.</strong></p>
        <p style='color: #666; margin-top: 30px;'>If you didn't request this, please ignore this email and your PIN will remain unchanged.</p>
        <hr style='border: none; border-top: 1px solid #eee; margin: 30px 0;'>
        <p style='color: #999; font-size: 12px;'>Market Hub - Your Commodity Trading Partner</p>
        <p style='color: #999; font-size: 11px;'>This is an automated message. Please do not reply to this email.</p>
    </div>
</body>
</html>
";

$server_host = $_SERVER['HTTP_HOST'] ?? 'markethub.app';
$server_host = preg_replace('/:\d+$/', '', $server_host);
$from_email = 'noreply@' . $server_host;

$headers  = "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: text/html; charset=UTF-8\r\n";
$headers .= "From: Market Hub <$from_email>\r\n";
$headers .= "Reply-To: $from_email\r\n";
$headers .= "Return-Path: $from_email\r\n";
$headers .= "X-Sender: $from_email\r\n";
$headers .= "X-Mailer: MarketHub/1.0\r\n";
$headers .= "Message-ID: <" . time() . "-" . md5($email) . "@" . $_SERVER['HTTP_HOST'] . ">\r\n";

$mail_sent = @mail($email, $email_subject, $email_body, $headers);

if (!$mail_sent) {
    error_log("Failed to send PIN reset email to: $email");
}

api_success([
    'email' => $email,
    'otp_sent' => $mail_sent,
], 'PIN reset code sent to your email.');
