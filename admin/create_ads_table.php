<?php
$conn = new mysqli('localhost', 'aaiacc_admin', 'Prasham123$', 'market_hub');
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

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

if ($conn->query($sql) === TRUE) {
    echo "Table ads created successfully";
} else {
    echo "Error creating table: " . $conn->error;
}
$conn->close();
?>
