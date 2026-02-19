<?php
/**
 * Market Hub API - Check Account Status (for pending users)
 * GET /api/check-status.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

$user_id = intval($_GET['user_id'] ?? 0);
$email = trim($_GET['email'] ?? '');

if (!$user_id && empty($email)) {
    api_error('User ID or email is required');
}

// Find user
if ($user_id) {
    $user = db_fetch_one("SELECT id, full_name, email, status, rejection_reason FROM users WHERE id = ?", 'i', [$user_id]);
} else {
    $user = db_fetch_one("SELECT id, full_name, email, status, rejection_reason FROM users WHERE email = ?", 's', [$email]);
}

if (!$user) {
    api_error('User not found');
}

api_success([
    'user_id' => $user['id'],
    'email' => $user['email'],
    'status' => $user['status'],
    'rejection_reason' => $user['status'] === 'rejected' ? $user['rejection_reason'] : null,
    'can_login' => $user['status'] === 'approved'
]);
