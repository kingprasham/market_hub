<?php
/**
 * Market Hub API - Check User Status & Profile
 * GET /api/profile.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

$user = verify_auth();

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
        'deviceToken' => $user['device_token'] ?? null,
        'createdAt' => $user['created_at'] ?? date('Y-m-d H:i:s')
    ]
]);
