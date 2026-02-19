<?php
/**
 * Market Hub API - Get Price Alerts
 * GET /api/get-price-alerts.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

$user = verify_auth();

try {
    $alerts = db_fetch_all(
        "SELECT * FROM price_alerts WHERE user_id = ? ORDER BY created_at DESC",
        "i",
        [$user['id']]
    );

    // Ensure array is returned
    if (!is_array($alerts)) {
        $alerts = [];
    }

    // Ensure numeric types are correct
    foreach ($alerts as &$alert) {
        $alert['id'] = (int)$alert['id'];
        $alert['target_price'] = (float)$alert['target_price'];
        $alert['is_active'] = (bool)$alert['is_active'];
        $alert['current_price'] = 0.0;
    }

    api_success([
        'alerts' => $alerts
    ]);
} catch (Exception $e) {
    api_error('Database error: ' . $e->getMessage());
}
