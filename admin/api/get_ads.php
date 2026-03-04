<?php
/**
 * Market Hub API - Get Dynamic Ads
 * Place this file at: https://mehrgrewal.com/markethub/api/get_ads.php
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
    // Fetch active ads
    $ads = db_fetch_all(
        "SELECT *
         FROM ads
         WHERE is_active = 1
         ORDER BY sort_order ASC, created_at DESC"
    );

    // Build base URL for assets
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $script_path = $_SERVER['SCRIPT_NAME']; 
    $api_dir = dirname($script_path); // /markethub/api
    $base_path = dirname($api_dir); // /markethub
    $base_url = $protocol . '://' . $host . $base_path . '/';

    $formatted_ads = [];
    foreach ($ads as $item) {
        $formatted_ads[] = [
            'id' => (int)$item['id'],
            'imagePath' => !empty($item['image_path']) ? $base_url . $item['image_path'] : '',
            'carouselTitle' => $item['title'],
            'carouselSubtitle' => $item['subtitle'],
            'companyName' => $item['company_name'],
            'heading' => $item['heading'],
            'infoItems' => json_decode($item['info_items'], true) ?? [],
            'contacts' => json_decode($item['contacts'], true) ?? [],
            'disclaimer' => $item['disclaimer']
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $formatted_ads
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server Error: ' . $e->getMessage()
    ]);
}
