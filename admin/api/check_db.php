<?php
define('ADMIN_PANEL', true);
require_once 'config.php';
$result = db_fetch_all("SHOW COLUMNS FROM news_hindi");
echo json_encode($result, JSON_PRETTY_PRINT);
$result2 = db_fetch_all("SELECT * FROM news_hindi");
echo json_encode($result2, JSON_PRETTY_PRINT);
?>
