-- Fix news title character limit
-- Change VARCHAR(255) to TEXT to allow longer titles (especially Hindi)
ALTER TABLE news MODIFY COLUMN title TEXT NOT NULL;
ALTER TABLE news_hindi MODIFY COLUMN title TEXT NOT NULL;
ALTER TABLE home_updates MODIFY COLUMN title TEXT NOT NULL;
ALTER TABLE circulars MODIFY COLUMN title TEXT NOT NULL;
