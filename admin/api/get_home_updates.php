<?php
/**
 * Market Hub API - Get Home Updates (Dedicated)
 * Place this file at: https://mehrgrewal.com/markethub/api/get_home_updates.php
 */

// Allow CORS for the mobile app
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

define('ADMIN_PANEL', true);
require_once 'config.php';

try {
    // Fetch active updates
    $updates = db_fetch_all(
        "SELECT id, title, description, image_path, pdf_path, created_at
         FROM home_updates
         WHERE is_active = 1
         ORDER BY created_at DESC
         LIMIT 10"
    );

    // Build base URL for assets
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $script_path = $_SERVER['SCRIPT_NAME']; 
    $api_dir = dirname($script_path); // /markethub/api
    $base_path = dirname($api_dir); // /markethub
    $base_url = $protocol . '://' . $host . $base_path . '/';

    $formatted_updates = [];
    foreach ($updates as $item) {
        $formatted_updates[] = [
            'id' => (string)$item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'imageUrl' => !empty($item['image_path']) ? $base_url . $item['image_path'] : null,
            'pdfUrl' => !empty($item['pdf_path']) ? $base_url . $item['pdf_path'] : null,
            'createdAt' => $item['created_at'],
            'isImportant' => true // Default to true for new updates section
        ];
    }

    echo json_encode([
        'success' => true,
        'updates' => $formatted_updates,
        'count' => count($formatted_updates)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server Error: ' . $e->getMessage()
    ]);
}
