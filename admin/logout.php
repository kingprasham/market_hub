<?php
/**
 * Market Hub Admin - Logout
 */
define('ADMIN_PANEL', true);

require_once 'includes/auth.php';

logout_admin();

header('Location: index.php');
exit;
