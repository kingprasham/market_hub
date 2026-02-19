<?php
/**
 * Pages Include Bootstrap
 * This file is included from pages/* and sets up the correct paths
 */

// Enable error reporting for debugging (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

define('ADMIN_PANEL', true);

// Get the admin root directory (two levels up from pages/includes)
// pages/includes/init.php -> pages/includes -> pages -> admin root
define('ADMIN_ROOT', dirname(dirname(__DIR__)));

// Include core files
require_once ADMIN_ROOT . '/config/database.php';
require_once ADMIN_ROOT . '/includes/auth.php';
require_once ADMIN_ROOT . '/includes/functions.php';
require_once ADMIN_ROOT . '/includes/upload.php';
require_once ADMIN_ROOT . '/api/config.php';  // For push notification functions

// Require login
require_login();

// Get flash message for display
$flash = get_flash();
