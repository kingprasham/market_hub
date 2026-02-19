<?php
/**
 * Market Hub API - Get Plans
 * GET /api/plans.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

// No auth required - plans are public
$plans = db_fetch_all(
    "SELECT id, name, description, price, duration_months, features 
     FROM plans 
     WHERE is_active = 1 
     ORDER BY price"
);

// Decode features JSON
foreach ($plans as &$plan) {
    $plan['features'] = json_decode($plan['features'], true) ?? [];
    $plan['price'] = floatval($plan['price']);
}

api_success([
    'plans' => $plans,
    'count' => count($plans)
]);
