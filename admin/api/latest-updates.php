<?php
/**
 * Market Hub API - Get Latest Updates (Combined)
 * GET /api/latest-updates.php?limit=20
 * Public endpoint - returns combined news, circulars, and home updates
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

// Get optional limit parameter (default 20)
$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;
$limit = min($limit, 100); // Max 100 items

// Build full URLs helper
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$script_path = $_SERVER['SCRIPT_NAME']; // e.g., /markethub/admin/api/latest-updates.php
$api_dir = dirname($script_path); // e.g., /markethub/admin/api
$base_path = dirname($api_dir); // e.g., /markethub/admin
$base_url = $protocol . '://' . $host . $base_path . '/';

// Fetch all content types
$all_updates = [];

// Set headers manually since ADMIN_PANEL prevents config.php from doing it
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

try {
    // 1. Get English news
    $news = db_fetch_all(
        "SELECT id, title, description, image_path, pdf_path, supporting_link as source_link, target_plans, created_at, 'news' as content_type
         FROM news
         WHERE is_active = 1"
    );
    foreach ($news as $item) {
        $all_updates[] = [
            'id' => $item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'imageUrl' => !empty($item['image_path']) ? $base_url . $item['image_path'] : null,
            'pdfUrl' => !empty($item['pdf_path']) ? $base_url . $item['pdf_path'] : null,
            'sourceLink' => $item['source_link'],
            'contentType' => 'news',
            'category' => 'News (English)',
            'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true),
            'createdAt' => date('Y-m-d H:i:s', strtotime($item['created_at']))
        ];
    }

    // 2. Get Hindi news
    $hindiNews = db_fetch_all(
        "SELECT id, title, description, image_path, pdf_path, supporting_link as source_link, target_plans, created_at, 'hindi_news' as content_type
         FROM news_hindi
         WHERE is_active = 1"
    );
    foreach ($hindiNews as $item) {
        $all_updates[] = [
            'id' => $item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'imageUrl' => !empty($item['image_path']) ? $base_url . $item['image_path'] : null,
            'pdfUrl' => !empty($item['pdf_path']) ? $base_url . $item['pdf_path'] : null,
            'sourceLink' => $item['source_link'],
            'contentType' => 'hindi_news',
            'category' => 'समाचार (हिंदी)',
            'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true),
            'createdAt' => date('Y-m-d H:i:s', strtotime($item['created_at']))
        ];
    }

    // 3. Get circulars
    $circulars = db_fetch_all(
        "SELECT id, title, description, image_path, pdf_path, target_plans, created_at, 'circular' as content_type
         FROM circulars
         WHERE is_active = 1"
    );
    foreach ($circulars as $item) {
        $all_updates[] = [
            'id' => $item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'imageUrl' => !empty($item['image_path']) ? $base_url . $item['image_path'] : null,
            'pdfUrl' => !empty($item['pdf_path']) ? $base_url . $item['pdf_path'] : null,
            'sourceLink' => null,
            'contentType' => 'circular',
            'category' => 'Circular',
            'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true),
            'createdAt' => date('Y-m-d H:i:s', strtotime($item['created_at']))
        ];
    }

    // 4. Get home updates
    $homeUpdates = db_fetch_all(
        "SELECT id, title, description, image_path, pdf_path, target_plans, created_at, 'home_update' as content_type
         FROM home_updates
         WHERE is_active = 1"
    );
    foreach ($homeUpdates as $item) {
        $all_updates[] = [
            'id' => $item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'imageUrl' => !empty($item['image_path']) ? $base_url . $item['image_path'] : null,
            'pdfUrl' => !empty($item['pdf_path']) ? $base_url . $item['pdf_path'] : null,
            'sourceLink' => null,
            'contentType' => 'home_update',
            'category' => 'Update',
            'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true),
            'createdAt' => date('Y-m-d H:i:s', strtotime($item['created_at']))
        ];
    }

    // Sort by created_at descending
    usort($all_updates, function($a, $b) {
        $timeA = strtotime($a['createdAt'] ?? 'now');
        $timeB = strtotime($b['createdAt'] ?? 'now');
        return $timeB - $timeA;
    });

    // Limit results
    $all_updates = array_slice($all_updates, 0, $limit);

    api_success([
        'updates' => $all_updates,
        'count' => count($all_updates),
        'total_available' => count($all_updates) 
    ]);

} catch (Exception $e) {
    api_error('Failed to fetch updates: ' . $e->getMessage());
}
