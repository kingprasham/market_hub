<?php
define('ADMIN_PANEL', true);
require_once __DIR__ . '/config.php';

try {
    $result = db_query("ALTER TABLE users ADD COLUMN company_name VARCHAR(255) NULL AFTER full_name");
    echo "Column added successfully.\n";
} catch (Exception $e) {
    echo "Error or already exists: " . $e->getMessage() . "\n";
}
