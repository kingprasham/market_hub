-- Market Hub Database Schema
-- Database: market_hub
-- Run this SQL to create all required tables

-- ============================================
-- ADMIN USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS admins (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default admin (password: admin123)
INSERT INTO admins (username, password_hash, email) VALUES 
('admin', '$2y$12$XWeP9a/gUXtubMlmvll4xeIXd.sVpHPk3X8ajGEF9aGkuysmNahvq', 'admin@markethub.com')
ON DUPLICATE KEY UPDATE id=id;

-- ============================================
-- SUBSCRIPTION PLANS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS plans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    duration_months INT DEFAULT 1,
    features JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default plans
INSERT INTO plans (name, description, price, duration_months, features) VALUES 
('Basic', 'Basic access to market data', 999.00, 1, '["Market Updates", "Basic News"]'),
('Pro', 'Professional access with alerts', 2499.00, 6, '["Market Updates", "All News", "Price Alerts", "Hindi News"]'),
('Premium', 'Full access to all features', 4999.00, 12, '["All Features", "Priority Support", "Economic Calendar", "Circulars"]')
ON DUPLICATE KEY UPDATE id=id;

-- ============================================
-- APP USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    whatsapp VARCHAR(15),
    pin_code VARCHAR(6),
    pin_hash VARCHAR(255),
    visiting_card VARCHAR(255),
    plan_id INT,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    rejection_reason TEXT,
    device_token VARCHAR(255),
    email_verified BOOLEAN DEFAULT FALSE,
    email_otp VARCHAR(10),
    otp_expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    plan_expires_at TIMESTAMP NULL,
    FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- HOME PAGE UPDATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS home_updates (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_path VARCHAR(255),
    pdf_path VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- NEWS (ENGLISH) TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS news (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_path VARCHAR(255),
    pdf_path VARCHAR(255),
    supporting_link VARCHAR(500),
    target_plans JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- NEWS HINDI TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS news_hindi (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_path VARCHAR(255),
    pdf_path VARCHAR(255),
    supporting_link VARCHAR(500),
    target_plans JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- CIRCULARS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS circulars (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_path VARCHAR(255),
    pdf_path VARCHAR(255),
    target_plans JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- USER FEEDBACK TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS feedback (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    message TEXT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- APP SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(50) UNIQUE NOT NULL,
    setting_value TEXT,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default settings
INSERT INTO settings (setting_key, setting_value) VALUES 
('terms_conditions', '<h2>Terms & Conditions</h2><p>Welcome to Market Hub. By using this application, you agree to the following terms...</p>'),
('about_us', '<h2>About Market Hub</h2><p>Market Hub is a comprehensive platform for metal market data and analysis.</p>'),
('contact_phone', '+91 9876543210'),
('contact_email', 'support@markethub.com'),
('contact_whatsapp', '+91 9876543210'),
('contact_address', 'Mumbai, Maharashtra, India'),
('firebase_service_account', '{
  "type": "service_account",
  "project_id": "market-hub-58dca",
  "private_key_id": "03722d3d8672c046d78eee11ea116a213baacc1a",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQD16C/dE7BLvqQ4\\nT03EefA99vz1xugEzoprj3jtaq/ZOxQMl6eSp1lyL+1S36tN8678gcf7YJy/aKtJ\\nDjIVa4xtHQERBl4O5sZKCheRLa6lU/0hKRIIuP/NuoxMKJlGucHi+NDeLBegTFob\\nNf7KNfhG94kxz6VK0zxqiX2fQdgzaLHIQebzFIKuts5d5J1KgMcvc4AEJYNPQ+88\\nr7XYwcSVRtmKuhFWy8CzjiSZ/zscLWnv1NPnA80cBKQSVB0sEeRnIZMTO3gyEQ66\\nTGweqm6hwgE+3hAuuvusK6HBxw3on0vV7zli0kTnjij1AsMQiASjOFes4BPXrxvd\\nd1Q+ANOJAgMBAAECggEAP4e2geu5wr/khmW6pjWIo0Ghtc+nFsLTkRlWeSP0fW9d\\nbSlrEiDpI26NZjlB9RgtT7Ap3eBmbq8YfX3M46rO80uogGEAQOJPPUahMxE1yyHJ\\nRl1petZsxBZbc7uTaenI1R5KO/PxQKkpKFmJU22hEJiYGcXXIt8y/yU5TsFAnXr/\\nuaMPKJIN4OuWPTsH4e1Mn2En6G6u02SOWWExVpdhzRE+GpgL5vmdoGT0MLu7Ov/C\\n8qKUKTkZTEpKCORIVMKo/hQNHxnOrm+3ohlVckPGYRS4lFwDiJc3lmcznT6DG1kq\\n4E1gvPTMIt2i4An7Z3hAwG+alpujmbL5UV02SbyeDwKBgQD8wU98NTKJesswQDF+\\nTrUiO0etkw8k1NBl8tmH1tKkFV71twR0TA9Nd44iQHMR39XiakmOAQhLpTw3tvWa\\n8nMA95lsnia+AivQQxEhqtmeSZ9s8JwOCpFDm4iqM2XrZFqcZPK6e49J1j0YzStH\\n3BSZkzZmf2WwKHrQ4m4FhTRowwKBgQD5EF6rfXY5LML++8Jj6FdXrn7DvngH+iOt\\nfG8qY796i8oOXH7ZixRwHpsk4WZNQUlDw5pGYKzeGreqacYD3mNjbaQmIzVnhCTt\\nZX00ZhVnA8Xewv0Kj7ansEBbEz4HboeOexMsuuRnwtNv4jeqmTTbXoECEh2O/WMp\\n8kgVF/5twwKBgDJWXXojLhlrNyQ45KJ/Elvq6m+LJizzpT1ojCIdin3bM7pD5MM0\\nkqee89OmekRJC9O3z0ZUtk46bi+6ZFejiXvb09Zp+NVGoWsssDDAUe7QQsvzb2Ds\\ngdmxFBqxec7Tgag8AotZKERQQoK5+bCqCAA97Uuke6AFr9ACCF9ZFAL5AoGARCXi\\ngXHWw1YoFLS2P7f3DhrEvLKFDUm4MWP21tZsMg/FvaA5ZTTU5si5EqJJ56GRdmUy\\n9UbGhg8xagN/FtfmwfHiFD1WA3j40awPUiMMgB9cKNOZgSZJiCCFu2XMdyQbGzU5\\nzedlT67TQ63WJWu+Nrfo/LQQOmvCkluktYDXMRkCgYA7dWi5WUWs2RMEHAAbaLrO\\n7E/Ruz3rkbYsvj1nKU2YaaiBxupFFG0fFg1SgdcdnjNQTsuH5sfGnSzatGtJMys4\\nxSD8Yzv8UUsPSyB70U33mB6LVPsWlQws5McWNfW7F6WL1VTOOnUeoUECBMFDLIYz\\n0aCA0WZEPtDSB3zXax8nnQ==\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@market-hub-58dca.iam.gserviceaccount.com",
  "client_id": "112989263646484850552",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40market-hub-58dca.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}')
ON DUPLICATE KEY UPDATE id=id;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_news_active ON news(is_active);
CREATE INDEX idx_circulars_active ON circulars(is_active);
CREATE INDEX idx_home_updates_active ON home_updates(is_active);

-- ============================================
-- PIN RESET COLUMNS (Required for forgot-pin flow)
-- ============================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_otp VARCHAR(10) DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_otp_expires TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_token VARCHAR(64) DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_reset_token_expires TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(512) DEFAULT NULL;

