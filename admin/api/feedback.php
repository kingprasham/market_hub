<?php
/**
 * Market Hub API - Submit Feedback
 * POST /api/feedback.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$user = verify_auth();

$data = get_json_input();
$message = trim($data['message'] ?? '');
$rating = intval($data['rating'] ?? 0);

if (empty($message)) {
    api_error('Feedback message is required');
}

if ($rating < 1 || $rating > 5) {
    $rating = null;
}

db_insert(
    "INSERT INTO feedback (user_id, message, rating) VALUES (?, ?, ?)",
    'isi',
    [$user['id'], $message, $rating]
);

api_success([], 'Thank you for your feedback!');
