<?php
/**
 * Utility to inspect cache and logs
 * Add ?clear=1 to delete the cache (forces fresh rebuild on next cron/webhook)
 */
$cache_file = __DIR__ . '/spot_cache.json';
$log_file = __DIR__ . '/spot_monitor.log';

if (isset($_GET['clear']) && $_GET['clear'] === '1') {
    if (file_exists($cache_file)) {
        unlink($cache_file);
        echo "Cache DELETED. Run the cron or edit a sheet to rebuild it.\n";
    } else {
        echo "Cache file did not exist.\n";
    }
    exit;
}

echo "--- CACHE STATS ---\n";
if (file_exists($cache_file)) {
    $cache = json_decode(file_get_contents($cache_file), true);
    echo "Sheets in cache: " . implode(", ", array_keys($cache)) . "\n";
    if (isset($cache['app_tab'])) {
        echo "App Tab entries: " . count($cache['app_tab']) . "\n";
        echo "Sample entry: Warehouse|COPPER MT = " . ($cache['app_tab']['Warehouse|COPPER MT'] ?? 'MISSING') . "\n";
    } else {
        echo "app_tab NOT found in cache!\n";
    }

    if (isset($cache['non_ferrous'])) {
        echo "\n--- non_ferrous: keys containing 'Zinc' or 'Hindustan' ---\n";
        $found = 0;
        foreach ($cache['non_ferrous'] as $key => $val) {
            if (stripos($key, 'zinc') !== false || stripos($key, 'hindustan') !== false) {
                echo "  $key = $val\n";
                $found++;
            }
        }
        if ($found === 0) echo "  (none found)\n";

        echo "\n--- DELHI non_ferrous cache keys (first 15) ---\n";
        $count = 0;
        foreach ($cache['non_ferrous'] as $key => $val) {
            if (strpos($key, 'DELHI') !== false) {
                echo "  $key = $val\n";
                if (++$count >= 15) { echo "  ...\n"; break; }
            }
        }

        echo "\n--- MUMBAI non_ferrous cache keys ---\n";
        foreach ($cache['non_ferrous'] as $key => $val) {
            if (strpos($key, 'MUMBAI') !== false) {
                echo "  $key = $val\n";
            }
        }
    }
} else {
    echo "Cache file not found.\n";
}

echo "\n--- LAST LOGS ---\n";
if (file_exists($log_file)) {
    $lines = file($log_file);
    echo implode("", array_slice($lines, -20));
} else {
    echo "Log file not found.\n";
}
