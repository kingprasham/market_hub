<?php
/**
 * Market Hub API - Add Price Alert
 * POST /api/add-price-alert.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$user = verify_auth();

// Get input
$data = get_json_input();
$metal = $data['metal'] ?? '';
$location = $data['location'] ?? 'All';
$target_price = $data['target_price'] ?? '';
$condition_type = $data['condition_type'] ?? '';

// Validate
if (empty($metal) || empty($target_price) || empty($condition_type)) {
    api_error('Missing required fields');
}

if (!in_array($condition_type, ['Above', 'Below'])) {
    api_error('Invalid condition type');
}

try {
    // Insert using db_query helper
    $sql = "INSERT INTO price_alerts (user_id, metal, location, target_price, condition_type, is_active, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())";
    $types = 'issds';
    $params = [$user['id'], $metal, $location, $target_price, $condition_type];

    $result = db_query($sql, $types, $params);

    api_success([
        'message' => 'Price alert created successfully'
    ]);

} catch (Exception $e) {
    api_error('Database error: ' . $e->getMessage());
}
