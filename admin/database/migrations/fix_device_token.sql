-- Migration: Increase device_token column length
-- Reason: FCM tokens can be longer than 255 characters, leading to truncation and session invalidation.
-- Applied to: users table

ALTER TABLE users MODIFY COLUMN device_token VARCHAR(512);
ALTER TABLE users MODIFY COLUMN fcm_token VARCHAR(512);
