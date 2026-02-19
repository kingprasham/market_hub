<?php
/**
 * Market Hub API - Update Profile
 * POST /api/update-profile.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

// Set headers manually
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

try {
    // Verify auth
    $user = verify_auth();
    $user_id = $user['id'];

    // Get input
    $full_name = $_POST['full_name'] ?? '';
    $email = $_POST['email'] ?? '';
    $phone = $_POST['phone'] ?? '';
    $whatsapp = $_POST['whatsapp'] ?? '';
    
    // Validate required fields
    if (empty($full_name)) api_error('Full name is required');
    if (empty($email)) api_error('Email is required');
    if (empty($phone)) api_error('Phone number is required');

    // Check if email already exists for another user
    $existing = db_fetch_one(
        "SELECT id FROM users WHERE email = ? AND id != ?", 
        'si', 
        [$email, $user_id]
    );
    
    if ($existing) {
        api_error('Email already registered by another user');
    }

    // Prepare update query
    $update_fields = [
        "full_name = ?",
        "email = ?",
        "phone = ?"
    ];
    $types = "sss";
    $params = [$full_name, $email, $phone];

    if (!empty($whatsapp)) {
        $update_fields[] = "whatsapp = ?";
        $types .= "s";
        $params[] = $whatsapp;
    }

    // Handle profile picture/visiting card upload if needed (future scope)
    // For now, just text fields

    $sql = "UPDATE users SET " . implode(", ", $update_fields) . " WHERE id = ?";
    $types .= "i";
    $params[] = $user_id;

    if (db_query($sql, $types, $params)) {
        // Fetch updated user
        $updated_user = db_fetch_one("SELECT * FROM users WHERE id = ?", 'i', [$user_id]);

        // Get plan info
        $plan = db_fetch_one("SELECT * FROM plans WHERE id = ?", 'i', [$updated_user['plan_id']]);

        // Parse phone numbers to extract country code and number
        $phoneCountryCode = '+91'; // Default
        $phoneNumber = $updated_user['phone'] ?? '';
        if (!empty($phoneNumber) && preg_match('/^(\+\d+)\s*(.+)$/', $phoneNumber, $matches)) {
            $phoneCountryCode = $matches[1];
            $phoneNumber = $matches[2];
        }

        $whatsappCountryCode = '+91'; // Default
        $whatsappNumber = $updated_user['whatsapp'] ?? '';
        if (!empty($whatsappNumber) && preg_match('/^(\+\d+)\s*(.+)$/', $whatsappNumber, $matches)) {
            $whatsappCountryCode = $matches[1];
            $whatsappNumber = $matches[2];
        }

        api_success([
            'message' => 'Profile updated successfully',
            'user' => [
                'id' => (string)$updated_user['id'],
                'fullName' => $updated_user['full_name'] ?? '',
                'email' => $updated_user['email'] ?? '',
                'phoneNumber' => $phoneNumber,
                'countryCode' => $phoneCountryCode,
                'whatsappNumber' => $whatsappNumber,
                'whatsappCountryCode' => $whatsappCountryCode,
                'pincode' => $updated_user['pincode'] ?? '',
                'visitingCardUrl' => $updated_user['visiting_card_url'] ?? null,
                'isEmailVerified' => (bool)($updated_user['email_verified'] ?? false),
                'isApproved' => $updated_user['status'] === 'approved',
                'isRejected' => $updated_user['status'] === 'rejected',
                'rejectionMessage' => $updated_user['rejection_message'] ?? null,
                'planId' => $updated_user['plan_id'] ? (string)$updated_user['plan_id'] : null,
                'planName' => $plan['name'] ?? null,
                'planExpiryDate' => $updated_user['plan_expires_at'] ?? null,
                'deviceToken' => $updated_user['device_token'] ?? null,
                'createdAt' => $updated_user['created_at'] ?? date('Y-m-d H:i:s')
            ]
        ]);
    } else {
        api_error('Failed to update profile');
    }

} catch (Exception $e) {
    api_error('Error: ' . $e->getMessage());
}
