<?php
/**
 * Market Hub API - Get App Settings
 * GET /api/settings.php
 */
define('ADMIN_PANEL', true);
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed', 405);
}

// No auth required for public settings
api_success([
    'settings' => [
        'terms_conditions' => get_setting('terms_conditions', ''),
        'about_us' => get_setting('about_us', ''),
        'contact' => [
            'phone' => get_setting('contact_phone', ''),
            'email' => get_setting('contact_email', ''),
            'whatsapp' => get_setting('contact_whatsapp', ''),
            'address' => get_setting('contact_address', '')
        ]
    ]
]);
