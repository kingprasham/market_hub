<?php
/**
 * Market Hub API - Get Notifications
 * 
 * Returns stored notifications (price alerts, system, etc.) for the Notifications tab.
 * 
 * GET /api/get_notifications.php
 * Query params:
 *   - limit (int, default 100)
 *   - offset (int, default 0)
 *   - type (string, optional: 'price_alert', 'system', etc.)
 */

define('ADMIN_PANEL', true);
require_once __DIR__ . '/config.php';

// Ensure table exists
$sql = "CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL DEFAULT 'price_alert',
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_created (created_at)
)";
db_query($sql);

$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 100;
$offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
$type = isset($_GET['type']) ? $_GET['type'] : null;

if ($limit > 200) $limit = 200;
if ($limit < 1) $limit = 100;
if ($offset < 0) $offset = 0;

try {
    if ($type) {
        $rows = db_fetch_all(
            "SELECT id, type, title, message, data, created_at 
             FROM notifications 
             WHERE type = ? 
             ORDER BY created_at DESC 
             LIMIT $limit OFFSET $offset",
            's',
            [$type]
        );
    } else {
        $rows = db_fetch_all(
            "SELECT id, type, title, message, data, created_at 
             FROM notifications 
             ORDER BY created_at DESC 
             LIMIT $limit OFFSET $offset"
        );
    }

    $notifications = [];
    foreach ($rows as $row) {
        $parsed_data = json_decode(isset($row['data']) ? $row['data'] : '{}', true);
        if (!is_array($parsed_data)) $parsed_data = [];
        
        $notifications[] = [
            'id'        => strval($row['id']),
            'type'      => $row['type'],
            'title'     => $row['title'],
            'message'   => $row['message'],
            'data'      => $parsed_data,
            'createdAt' => $row['created_at'],
        ];
    }

    api_success([
        'notifications' => $notifications,
        'count'         => count($notifications),
        'offset'        => $offset,
        'limit'         => $limit,
    ]);
} catch (Exception $e) {
    api_error('Failed to fetch notifications: ' . $e->getMessage(), 500);
}
?>
