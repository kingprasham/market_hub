<?php
/**
 * Market Hub API - Login
 * POST /api/login.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$data = get_json_input();
$email = trim(strtolower($data['email'] ?? ''));
$pin = trim($data['pin'] ?? '');
$device_token = trim($data['device_token'] ?? '');

if (empty($email) || empty($pin)) {
    api_error('Email and PIN are required');
}

// Get user
$user = db_fetch_one("SELECT * FROM users WHERE email = ?", 's', [$email]);

if (!$user) {
    api_error('Account not found');
}

// Check status
if ($user['status'] === 'pending') {
    api_error('Your account is pending approval', 403);
}

if ($user['status'] === 'rejected') {
    api_error('Your account was rejected. Reason: ' . ($user['rejection_reason'] ?? 'Not specified'), 403);
}

// Verify PIN
if (!verify_pin($pin, $user['pin_hash'])) {
    api_error('Invalid PIN');
}

// Check plan expiry
if ($user['plan_expires_at'] && strtotime($user['plan_expires_at']) < time()) {
    api_error('Your subscription has expired. Please contact support.', 403);
}

// Generate new device token if not provided (for session management)
if (empty($device_token)) {
    $device_token = bin2hex(random_bytes(32));
}

// Update device token and FCM token
// Note: Client sends 'device_token' as FCM token in body sometimes, 
// need to check if it's a valid FCM token or just session ID.
// For now, if client sends 'fcm_token' specifically, use it.
$fcm_token = trim($data['fcm_token'] ?? '');
if (empty($fcm_token) && !empty($data['device_token']) && strlen($data['device_token']) > 50) {
    // Assume long device_token is FCM token
    $fcm_token = $data['device_token'];
}

$sql = "UPDATE users SET device_token = ?";
$params = [$device_token];
$types = 's';

if (!empty($fcm_token)) {
    $sql .= ", fcm_token = ?";
    $params[] = $fcm_token;
    $types .= 's';
}

$sql .= " WHERE id = ?";
$params[] = $user['id'];
$types .= 'i';

db_query($sql, $types, $params);

// Generate auth token
$auth_token = base64_encode($user['id'] . ':' . $device_token);

// Get plan info
$plan = db_fetch_one("SELECT * FROM plans WHERE id = ?", 'i', [$user['plan_id']]);

// Parse phone numbers to extract country code and number
$phoneCountryCode = '+91'; // Default
$phoneNumber = $user['phone'] ?? '';
if (!empty($phoneNumber) && preg_match('/^(\+\d+)\s*(.+)$/', $phoneNumber, $matches)) {
    $phoneCountryCode = $matches[1];
    $phoneNumber = $matches[2];
}

$whatsappCountryCode = '+91'; // Default
$whatsappNumber = $user['whatsapp'] ?? '';
if (!empty($whatsappNumber) && preg_match('/^(\+\d+)\s*(.+)$/', $whatsappNumber, $matches)) {
    $whatsappCountryCode = $matches[1];
    $whatsappNumber = $matches[2];
}

api_success([
    'user' => [
        'id' => (string)$user['id'],
        'fullName' => $user['full_name'] ?? '',
        'email' => $user['email'] ?? '',
        'phoneNumber' => $phoneNumber,
        'countryCode' => $phoneCountryCode,
        'whatsappNumber' => $whatsappNumber,
        'whatsappCountryCode' => $whatsappCountryCode,
        'pincode' => $user['pincode'] ?? '',
        'visitingCardUrl' => $user['visiting_card_url'] ?? null,
        'isEmailVerified' => (bool)($user['email_verified'] ?? false),
        'isApproved' => $user['status'] === 'approved',
        'isRejected' => $user['status'] === 'rejected',
        'rejectionMessage' => $user['rejection_message'] ?? null,
        'planId' => $user['plan_id'] ? (string)$user['plan_id'] : null,
        'planName' => $plan['name'] ?? null,
        'planExpiryDate' => $user['plan_expires_at'] ?? null,
        'deviceToken' => $device_token,
        'createdAt' => $user['created_at'] ?? date('Y-m-d H:i:s')
    ],
    'auth_token' => $auth_token
], 'Login successful');
