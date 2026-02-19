<?php
/**
 * Market Hub Admin - Session & Authentication Functions
 */

// Prevent direct access
if (!defined('ADMIN_PANEL')) {
    die('Direct access not allowed');
}

// Session configuration
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);
ini_set('session.cookie_samesite', 'Strict');

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Session timeout in seconds (30 minutes)
define('SESSION_TIMEOUT', 1800);

/**
 * Check if user is logged in
 */
function is_logged_in() {
    if (!isset($_SESSION['admin_id']) || !isset($_SESSION['last_activity'])) {
        return false;
    }
    
    // Check session timeout
    if (time() - $_SESSION['last_activity'] > SESSION_TIMEOUT) {
        session_destroy();
        return false;
    }
    
    // Update last activity
    $_SESSION['last_activity'] = time();
    return true;
}

/**
 * Require login - redirect if not authenticated
 */
function require_login() {
    if (!is_logged_in()) {
        header('Location: /admin/index.php?error=session_expired');
        exit;
    }
}

/**
 * Login admin user
 */
function login_admin($username, $password) {
    $admin = db_fetch_one(
        "SELECT id, username, password_hash FROM admins WHERE username = ?",
        's',
        [$username]
    );
    
    if ($admin && password_verify($password, $admin['password_hash'])) {
        // Regenerate session ID to prevent fixation
        session_regenerate_id(true);
        
        $_SESSION['admin_id'] = $admin['id'];
        $_SESSION['admin_username'] = $admin['username'];
        $_SESSION['last_activity'] = time();
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        
        return true;
    }
    
    return false;
}

/**
 * Logout admin user
 */
function logout_admin() {
    $_SESSION = [];
    
    if (ini_get("session.use_cookies")) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
            $params["path"], $params["domain"],
            $params["secure"], $params["httponly"]
        );
    }
    
    session_destroy();
}

/**
 * Generate CSRF token
 */
function csrf_token() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Verify CSRF token
 */
function verify_csrf($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

/**
 * Get CSRF input field HTML
 */
function csrf_field() {
    return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars(csrf_token()) . '">';
}

/**
 * Hash password securely
 */
function hash_password($password) {
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
}

/**
 * Get current admin ID
 */
function current_admin_id() {
    return $_SESSION['admin_id'] ?? null;
}

/**
 * Get current admin username
 */
function current_admin_username() {
    return $_SESSION['admin_username'] ?? 'Admin';
}
