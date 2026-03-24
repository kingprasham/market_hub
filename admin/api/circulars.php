<?php
/**
 * Market Hub API - Get Circulars
 * GET /api/circulars.php
 * Public endpoint - returns all active circulars
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

// Public endpoint - no auth required

try {
    // Get active circulars
    $all_circulars = db_fetch_all(
        "SELECT id, title, description, pdf_path, image_path, target_plans, created_at
         FROM circulars
         WHERE is_active = 1
         ORDER BY created_at DESC"
    );

    // Build full URLs - Get the protocol and host
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    
    // Get the base path - uploads are stored in admin/uploads/
    $script_path = $_SERVER['SCRIPT_NAME'];
    $api_dir = dirname($script_path);
    $base_path = dirname($api_dir);
    
    $base_url = $protocol . '://' . $host . $base_path . '/';
    
    $circulars = [];
    foreach ($all_circulars as $item) {
        // Construct full URLs for images and PDFs
        $imageUrl = null;
        $pdfUrl = null;
    
        if (!empty($item['image_path'])) {
            $imageUrl = $base_url . $item['image_path'];
        }
    
        if (!empty($item['pdf_path'])) {
            $pdfUrl = $base_url . $item['pdf_path'];
        }
    
        $circulars[] = [
            'id' => $item['id'],
            'title' => $item['title'],
            'description' => $item['description'],
            'pdfUrl' => $pdfUrl,
            'imageUrl' => $imageUrl,
            'createdAt' => date('Y-m-d H:i:s', strtotime($item['created_at'])),
            'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true)
        ];
    }
} catch (Exception $e) {
    api_error('Failed to fetch circulars: ' . $e->getMessage());
}

api_success([
    'circulars' => $circulars,
    'count' => count($circulars)
]);
