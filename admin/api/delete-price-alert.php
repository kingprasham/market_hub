<?php
/**
 * Market Hub API - Delete Price Alert
 * POST /api/delete-price-alert.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed', 405);
}

$user = verify_auth();

$data = get_json_input();
$alert_id = $data['alert_id'] ?? '';

if (empty($alert_id)) {
    api_error('Missing alert_id');
}

try {
    // Verify ownership and delete
    db_query(
        "DELETE FROM price_alerts WHERE id = ? AND user_id = ?",
        "ii",
        [$alert_id, $user['id']]
    );

    api_success(['message' => 'Alert deleted successfully']);

} catch (Exception $e) {
    api_error('Database error: ' . $e->getMessage());
}
