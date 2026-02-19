<?php
/**
 * Market Hub Admin - Helper Functions
 */

// Prevent direct access
if (!defined('ADMIN_PANEL')) {
    die('Direct access not allowed');
}

/**
 * Sanitize output for HTML display
 */
function e($string) {
    return htmlspecialchars($string ?? '', ENT_QUOTES, 'UTF-8');
}

/**
 * Format date for display
 */
function format_date($date, $format = 'd M Y, h:i A') {
    if (empty($date)) return '-';
    return date($format, strtotime($date));
}

/**
 * Format currency
 */
function format_currency($amount) {
    return '₹' . number_format($amount, 2);
}

/**
 * Get status badge HTML
 */
function status_badge($status) {
    $badges = [
        'pending' => '<span class="badge bg-warning text-dark">Pending</span>',
        'approved' => '<span class="badge bg-success">Approved</span>',
        'rejected' => '<span class="badge bg-danger">Rejected</span>',
        'active' => '<span class="badge bg-success">Active</span>',
        'inactive' => '<span class="badge bg-secondary">Inactive</span>',
    ];
    return $badges[$status] ?? '<span class="badge bg-secondary">' . e($status) . '</span>';
}

/**
 * Set flash message
 */
function set_flash($type, $message) {
    $_SESSION['flash'] = [
        'type' => $type,
        'message' => $message
    ];
}

/**
 * Get and clear flash message
 */
function get_flash() {
    if (isset($_SESSION['flash'])) {
        $flash = $_SESSION['flash'];
        unset($_SESSION['flash']);
        return $flash;
    }
    return null;
}

/**
 * Redirect with message
 */
function redirect($url, $type = null, $message = null) {
    if ($type && $message) {
        set_flash($type, $message);
    }
    header("Location: $url");
    exit;
}

/**
 * Get base URL - dynamically detects the admin folder path
 */
function base_url($path = '') {
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    
    // Detect the admin folder path from current script
    $script_path = dirname($_SERVER['SCRIPT_NAME']);
    // If we're in pages/ folder, go up one level
    if (preg_match('/\/pages$/i', $script_path)) {
        $script_path = dirname($script_path);
    }
    // Ensure trailing slash
    $script_path = rtrim($script_path, '/') . '/';
    
    return "$protocol://$host$script_path$path";
}

/**
 * Check if current page matches
 */
function is_active_page($page) {
    $current = basename($_SERVER['PHP_SELF'], '.php');
    return $current === $page ? 'active' : '';
}

/**
 * Truncate text
 */
function truncate($text, $length = 100) {
    if (strlen($text) <= $length) return e($text);
    return e(substr($text, 0, $length)) . '...';
}

/**
 * Generate random string
 */
function random_string($length = 32) {
    return bin2hex(random_bytes($length / 2));
}

/**
 * Get file extension
 */
function get_extension($filename) {
    return strtolower(pathinfo($filename, PATHINFO_EXTENSION));
}

/**
 * Format file size
 */
function format_size($bytes) {
    $units = ['B', 'KB', 'MB', 'GB'];
    $i = 0;
    while ($bytes >= 1024 && $i < count($units) - 1) {
        $bytes /= 1024;
        $i++;
    }
    return round($bytes, 2) . ' ' . $units[$i];
}

/**
 * JSON response for AJAX
 */
function json_response($data, $status = 200) {
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

/**
 * Get plan names as array
 */
function get_plan_names() {
    $plans = db_fetch_all("SELECT id, name FROM plans WHERE is_active = 1 ORDER BY price");
    $result = [];
    foreach ($plans as $plan) {
        $result[$plan['id']] = $plan['name'];
    }
    return $result;
}

/**
 * Format target plans for display
 */
function format_target_plans($json) {
    if (empty($json)) return 'All Plans';
    
    $targets = json_decode($json, true);
    if (!is_array($targets)) return 'All Plans';
    
    if (in_array('all', $targets)) return 'All Plans';
    
    $plans = get_plan_names();
    $names = [];
    foreach ($targets as $id) {
        if (isset($plans[$id])) {
            $names[] = $plans[$id];
        }
    }
    
    return empty($names) ? 'All Plans' : implode(', ', $names);
}

/**
 * Send email (basic PHP mail)
 */
function send_email($to, $subject, $body) {
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
    $headers .= "From: Market Hub <noreply@markethub.com>\r\n";
    
    return mail($to, $subject, $body, $headers);
}

/**
 * Generate OTP
 */
function generate_otp($length = 6) {
    return str_pad(random_int(0, pow(10, $length) - 1), $length, '0', STR_PAD_LEFT);
}

/**
 * Hash PIN securely
 */
function hash_pin($pin) {
    return password_hash($pin, PASSWORD_BCRYPT);
}

/**
 * Verify PIN
 */
function verify_pin($pin, $hash) {
    return password_verify($pin, $hash);
}
