<?php
/**
 * Market Hub Admin - Add Ads Table Migration
 * Run this by visiting: /admin/database/migrations/add_ads_table.php
 */

define('ADMIN_PANEL', true);
$env_path = __DIR__ . '/../../.env';
if (file_exists($env_path)) {
    $env = parse_ini_file($env_path);
    if ($env) {
        foreach ($env as $key => $value) {
            $_ENV[$key] = $value;
        }
    }
}
require_once __DIR__ . '/../../config/database.php';

try {
    // 1. Create ads table
    $sql = "CREATE TABLE IF NOT EXISTS ads (
        id INT PRIMARY KEY AUTO_INCREMENT,
        title VARCHAR(255) NOT NULL,
        subtitle VARCHAR(255),
        company_name VARCHAR(255),
        heading VARCHAR(255),
        image_path VARCHAR(255),
        info_items JSON,
        contacts JSON,
        disclaimer TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        sort_order INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";

    db_query($sql);
    echo "Successfully created `ads` table.<br>";

    // Optional: seed default ads data? For now, we'll start empty and rely on hardcoded fallback in Flutter.

    echo "<br>Migration completed successfully!";
    echo "<br><br><a href='../../index.php'>Return to Dashboard</a>";

} catch (Exception $e) {
    echo "<h1>Migration Failed</h1>";
    echo "<p>Error: " . htmlspecialchars($e->getMessage()) . "</p>";
}
