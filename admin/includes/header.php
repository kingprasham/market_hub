<?php
/**
 * Market Hub Admin - Layout Header
 * Include this at the top of every authenticated page
 */
if (!defined('ADMIN_PANEL')) {
    define('ADMIN_PANEL', true);
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/upload.php';

// Require login
require_login();

// Get flash message
$flash = get_flash();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= e($page_title ?? 'Dashboard') ?> - Market Hub Admin</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <!-- DataTables -->
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link href="../assets/css/style.css" rel="stylesheet">
</head>
<body>
    <!-- Sidebar -->
    <nav class="sidebar">
        <div class="sidebar-brand">
            <h2>Market<span>Hub</span></h2>
        </div>
        
        <ul class="sidebar-menu">
            <li>
                <a href="dashboard.php" class="<?= is_active_page('dashboard') ?>">
                    <i class="bi bi-speedometer2"></i> Dashboard
                </a>
            </li>
            
            <li class="menu-header">User Management</li>
            <li>
                <a href="users.php" class="<?= is_active_page('users') ?>">
                    <i class="bi bi-people"></i> All Users
                </a>
            </li>
            <li>
                <a href="users.php?status=pending" class="<?= isset($_GET['status']) && $_GET['status'] === 'pending' ? 'active' : '' ?>">
                    <i class="bi bi-hourglass-split"></i> Pending Approvals
                </a>
            </li>
            <li>
                <a href="plans.php" class="<?= is_active_page('plans') ?>">
                    <i class="bi bi-credit-card"></i> Plans
                </a>
            </li>
            
            <li class="menu-header">Content Management</li>
            <li>
                <a href="home_updates.php" class="<?= is_active_page('home_updates') ?>">
                    <i class="bi bi-house-up"></i> Home Updates
                </a>
            </li>
            <li>
                <a href="ads.php" class="<?= is_active_page('ads') ?>">
                    <i class="bi bi-badge-ad"></i> Manage Ads
                </a>
            </li>
            <li>
                <a href="news.php" class="<?= is_active_page('news') ?>">
                    <i class="bi bi-newspaper"></i> News (English)
                </a>
            </li>
            <li>
                <a href="news_hindi.php" class="<?= is_active_page('news_hindi') ?>">
                    <i class="bi bi-translate"></i> News (Hindi)
                </a>
            </li>
            <li>
                <a href="circulars.php" class="<?= is_active_page('circulars') ?>">
                    <i class="bi bi-file-earmark-pdf"></i> Circulars
                </a>
            </li>
            
            <li class="menu-header">System</li>
            <li>
                <a href="feedback.php" class="<?= is_active_page('feedback') ?>">
                    <i class="bi bi-chat-dots"></i> Feedback
                </a>
            </li>
            <li>
                <a href="settings.php" class="<?= is_active_page('settings') ?>">
                    <i class="bi bi-gear"></i> Settings
                </a>
            </li>
            <li>
                <a href="../logout.php" onclick="return confirm('Are you sure you want to logout?')">
                    <i class="bi bi-box-arrow-left"></i> Logout
                </a>
            </li>
        </ul>
    </nav>
    
    <!-- Top Navbar -->
    <nav class="top-navbar">
        <h1 class="page-title"><?= e($page_title ?? 'Dashboard') ?></h1>
        <div class="admin-info">
            <span class="text-muted">Welcome,</span>
            <strong><?= e(current_admin_username()) ?></strong>
            <div class="admin-avatar">
                <?= strtoupper(substr(current_admin_username(), 0, 1)) ?>
            </div>
        </div>
    </nav>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Flash Messages -->
        <?php if ($flash): ?>
        <div class="alert alert-<?= $flash['type'] === 'error' ? 'danger' : $flash['type'] ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?= $flash['type'] === 'success' ? 'check-circle' : ($flash['type'] === 'error' ? 'exclamation-circle' : 'info-circle') ?> me-2"></i>
            <?= e($flash['message']) ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <?php endif; ?>
