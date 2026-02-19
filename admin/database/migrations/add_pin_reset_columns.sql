-- Migration: Add PIN Reset Columns to Users Table
-- Execute this SQL in your database

ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_otp VARCHAR(6) NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_otp_expires DATETIME NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_token VARCHAR(64) NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_token_expires DATETIME NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pin_reset_token ON users(pin_reset_token);
CREATE INDEX IF NOT EXISTS idx_pin_reset_otp_expires ON users(pin_reset_otp_expires);
