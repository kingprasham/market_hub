<?php
/**
 * Market Hub API - Get Home Updates
 * GET /api/home-updates.php
 * Public endpoint - no auth required
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

// Public endpoint - no auth required

$updates = db_fetch_all(
    "SELECT id, title, description, image_path, pdf_path, target_plans, created_at
     FROM home_updates
     WHERE is_active = 1
     ORDER BY created_at DESC"
);

// Build full URLs - Get the protocol and host
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];

// Get the base path - uploads are stored in admin/uploads/
$script_path = $_SERVER['SCRIPT_NAME']; // e.g., /markethub/admin/api/home-updates.php
$api_dir = dirname($script_path); // e.g., /markethub/admin/api
$base_path = dirname($api_dir); // e.g., /markethub/admin

$base_url = $protocol . '://' . $host . $base_path . '/';

$formatted_updates = [];
foreach ($updates as $item) {
    // Construct full URLs for images and PDFs
    $imageUrl = null;
    $pdfUrl = null;

    if (!empty($item['image_path'])) {
        $imageUrl = $base_url . $item['image_path'];
    }

    if (!empty($item['pdf_path'])) {
        $pdfUrl = $base_url . $item['pdf_path'];
    }

    $formatted_updates[] = [
        'id' => $item['id'],
        'title' => $item['title'],
        'description' => $item['description'],
        'imageUrl' => $imageUrl,
        'pdfUrl' => $pdfUrl,
        'createdAt' => $item['created_at'],
        'targetPlans' => json_decode($item['target_plans'] ?? '["all"]', true)
    ];
}

api_success([
    'updates' => $formatted_updates,
    'count' => count($formatted_updates)
]);
