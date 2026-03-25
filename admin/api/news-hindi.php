<?php
/**
 * Market Hub API - Get Hindi News
 * GET /api/news-hindi.php
 * Public endpoint - returns all active Hindi news
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

// Set headers manually since ADMIN_PANEL prevents config.php from doing it
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

// Public endpoint - no auth required

try {
    // Get active Hindi news
    $all_news = db_fetch_all(
        "SELECT id, title, description, image_path, pdf_path, supporting_link, target_plans, created_at
         FROM news_hindi
         WHERE is_active = 1
         ORDER BY created_at DESC"
    );

    // Build full URLs - Get the protocol and host
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];

    // Get the base path - uploads are stored in admin/uploads/
    $script_path = $_SERVER['SCRIPT_NAME']; // e.g., /markethub/admin/api/news-hindi.php
    $api_dir = dirname($script_path); // e.g., /markethub/admin/api
    $base_path = dirname($api_dir); // e.g., /markethub/admin

    $base_url = $protocol . '://' . $host . $base_path . '/';

    $news = [];
    foreach ($all_news as $item) {
        // Construct full URLs for images and PDFs
        $imageUrl = null;
        $pdfUrl = null;

        if (!empty($item['image_path'])) {
            $imageUrl = $base_url . $item['image_path'];
        }

        if (!empty($item['pdf_path'])) {
            $pdfUrl = $base_url . $item['pdf_path'];
        }

        $news[] = [
            'id' => $item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'imageUrl' => $imageUrl,
            'pdfUrl' => $pdfUrl,
            'link' => $item['supporting_link'],
            'createdAt' => date('Y-m-d H:i:s', strtotime($item['created_at'])),
            'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true)
        ];
    }
    
    api_success([
        'news' => $news,
        'count' => count($news)
    ]);

} catch (Exception $e) {
    api_error('Failed to fetch Hindi news: ' . $e->getMessage());
}
?>
