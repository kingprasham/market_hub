<?php
/**
 * Market Hub Admin Dashboard - Database Configuration
 * 
 * Database: market_hub
 * Host: localhost
 * User: aaiacc_admin
 * Pass: Prasham123$
 */

// Prevent direct access
if (!defined('ADMIN_PANEL')) {
    die('Direct access not allowed');
}

// Database credentials
define('DB_HOST', 'localhost');
define('DB_NAME', 'market_hub');
define('DB_USER', 'aaiacc_admin');
define('DB_PASS', 'Prasham123$');

// Create database connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set charset to UTF-8 for proper Unicode support (Hindi)
$conn->set_charset("utf8mb4");

/**
 * Execute a prepared statement with parameters
 * 
 * @param string $sql SQL query with placeholders
 * @param string $types Parameter types (i=int, s=string, d=double, b=blob)
 * @param array $params Parameters to bind
 * @return mysqli_result|bool Result or false on failure
 */
function db_query($sql, $types = '', $params = []) {
    global $conn;
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        error_log("Prepare failed: " . $conn->error);
        return false;
    }
    
    if (!empty($types) && !empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    if (!$stmt->execute()) {
        error_log("Execute failed: " . $stmt->error);
        return false;
    }
    
    $result = $stmt->get_result();
    return $result !== false ? $result : true;
}

/**
 * Get single row from query
 */
function db_fetch_one($sql, $types = '', $params = []) {
    $result = db_query($sql, $types, $params);
    if ($result && $result instanceof mysqli_result) {
        return $result->fetch_assoc();
    }
    return null;
}

/**
 * Get all rows from query
 */
function db_fetch_all($sql, $types = '', $params = []) {
    $result = db_query($sql, $types, $params);
    if ($result && $result instanceof mysqli_result) {
        return $result->fetch_all(MYSQLI_ASSOC);
    }
    return [];
}

/**
 * Insert and return last insert ID
 */
function db_insert($sql, $types = '', $params = []) {
    global $conn;
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        error_log("Prepare failed: " . $conn->error);
        return false;
    }
    
    if (!empty($types) && !empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    if (!$stmt->execute()) {
        error_log("Execute failed: " . $stmt->error);
        return false;
    }
    
    return $conn->insert_id;
}

/**
 * Escape string for safe output
 */
function db_escape($string) {
    global $conn;
    return $conn->real_escape_string($string);
}
