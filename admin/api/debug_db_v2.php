<?php
define('ADMIN_PANEL', true);
try {
    require_once __DIR__ . '/config.php';
    global $conn;
    
    if (!$conn) {
        echo "DATABASE CONNECTION IS NULL\n";
        exit;
    }
    
    echo "Database connected successfully.\n";
    
    $news_count = db_fetch_one("SELECT COUNT(*) as total FROM news")['total'] ?? 0;
    $hindi_news_count = db_fetch_one("SELECT COUNT(*) as total FROM news_hindi")['total'] ?? 0;
    $circular_count = db_fetch_one("SELECT COUNT(*) as total FROM circulars")['total'] ?? 0;
    
    echo "English News Count: $news_count\n";
    echo "Hindi News Count: $hindi_news_count\n";
    echo "Circular Count: $circular_count\n";
    
    if ($news_count > 0) {
        $sample = db_fetch_one("SELECT * FROM news LIMIT 1");
        echo "Sample English News Keys: " . implode(', ', array_keys($sample)) . "\n";
    }
    
    if ($hindi_news_count > 0) {
        $sample = db_fetch_one("SELECT * FROM news_hindi LIMIT 1");
        echo "Sample Hindi News Keys: " . implode(', ', array_keys($sample)) . "\n";
    } else {
        echo "WARNING: news_hindi table is empty!\n";
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
}
?>
