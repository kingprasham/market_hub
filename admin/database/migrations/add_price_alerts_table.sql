-- Migration: Add price_alerts table
-- Run this SQL to create the price_alerts table

CREATE TABLE IF NOT EXISTS `price_alerts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `metal` VARCHAR(100) NOT NULL,
    `location` VARCHAR(100) DEFAULT 'All',
    `target_price` DECIMAL(12,2) NOT NULL,
    `condition_type` ENUM('Above', 'Below') NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `triggered_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_metal` (`metal`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
