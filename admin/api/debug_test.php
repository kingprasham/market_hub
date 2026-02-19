<?php
/**
 * Market Hub API - Debug/Test Script
 * Upload this to your server to diagnose issues
 * DELETE AFTER TESTING!
 */

// Define constant to bypass access check
define('ADMIN_PANEL', true);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Include database
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$results = [];

// Test 1: Check database connection
try {
    $test = db_fetch_one("SELECT 1 as test");
    $results['database_connection'] = $test ? 'OK' : 'FAILED';
} catch (Exception $e) {
    $results['database_connection'] = 'ERROR: ' . $e->getMessage();
}

// Test 2: Check users table columns
try {
    $columns = db_fetch_all("DESCRIBE users");
    $column_names = array_column($columns, 'Field');
    $results['users_columns'] = $column_names;
} catch (Exception $e) {
    $results['users_columns'] = 'ERROR: ' . $e->getMessage();
}

// Test 3: Check if uploads directory exists
$dirs_to_check = [
    'uploads' => __DIR__ . '/../uploads',
    'visiting_cards' => __DIR__ . '/../uploads/visiting_cards',
    'news' => __DIR__ . '/../uploads/news',
    'circulars' => __DIR__ . '/../uploads/circulars',
];

foreach ($dirs_to_check as $name => $path) {
    $results['directory_' . $name] = [
        'exists' => is_dir($path),
        'writable' => is_writable($path),
        'path' => realpath($path) ?: $path
    ];
}

// Test 4: Check if generate_otp function exists
$results['generate_otp_exists'] = function_exists('generate_otp');

// Test 5: Try a test insert (not actually inserting, just checking syntax)
try {
    // Prepare statement only to check syntax
    global $conn;
    $stmt = $conn->prepare("INSERT INTO users (full_name, email, phone, whatsapp, plan_id, visiting_card, email_otp, otp_expires_at, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')");
    if ($stmt) {
        $results['insert_prepare'] = 'OK';
        $stmt->close();
    } else {
        $results['insert_prepare'] = 'FAILED: ' . $conn->error;
    }
} catch (Exception $e) {
    $results['insert_prepare'] = 'ERROR: ' . $e->getMessage();
}

// Test 6: Check PHP version
$results['php_version'] = phpversion();

// Test 7: Check if mail function exists
$results['mail_function'] = function_exists('mail');

echo json_encode($results, JSON_PRETTY_PRINT);
