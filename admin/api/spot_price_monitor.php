<?php
/**
 * Spot Price Monitor - Cron Script
 * 
 * Polls Google Sheets for spot price changes and sends FCM push notifications.
 * 
 * Usage: Run via cron every minute:
 *   * * * * * php /path/to/spot_price_monitor.php
 * 
 * Can also be triggered via HTTP for testing:
 *   GET /api/spot_price_monitor.php?key=YOUR_CRON_SECRET
 */

// Prevent direct browser access without secret key
$is_cli = php_sapi_name() === 'cli';
if (!$is_cli) {
    $cron_key = isset($_GET['key']) ? $_GET['key'] : '';
    $expected_key = 'mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC'; // Strong 40-char secret
    if ($cron_key !== $expected_key) {
        http_response_code(403);
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
}

define('ADMIN_PANEL', true);
require_once __DIR__ . '/config.php';

// ─── Configuration ───────────────────────────────────────────────
$CACHE_FILE = __DIR__ . '/spot_cache.json';
$LOG_FILE = __DIR__ . '/spot_monitor.log';

// Google Sheet IDs (same as in Flutter app)
$SHEETS_TO_MONITOR = [
    'non_ferrous' => [
        'id'   => '1VrCzC-sDcri5hO_TWfpHGx3ua7iaScLAtf-CFwQYBsI',
        'gid'  => '365100361',
        'label' => 'Non-Ferrous',
    ],
    'ferrous' => [
        'id'   => '1MGL9LrQn0M3WiHZYWnuGNukgqglezk3zWkzak2OXwg4',
        'gid'  => '0',
        'label' => 'Steel',
    ],
    'minor' => [
        'id'   => '1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM',
        'gid'  => '1353908069',
        'label' => 'Minor and Ferro',
    ],
];

// ─── Ensure notifications table exists ───────────────────────────
ensure_notifications_table();

// ─── Main Logic ──────────────────────────────────────────────────
$log_func = function($msg) use ($is_cli, $LOG_FILE) {
    $timestamp = date('Y-m-d H:i:s');
    $line = "[$timestamp] $msg";
    if ($is_cli) {
        echo $line . "\n";
    }
    // Always write to log file for server-side debugging
    @file_put_contents($LOG_FILE, $line . "\n", FILE_APPEND | LOCK_EX);
};

$log_func("Spot Price Monitor: Starting check...");

// Load previous cache
$cache = [];
if (file_exists($CACHE_FILE)) {
    $raw = file_get_contents($CACHE_FILE);
    if ($raw !== false) {
        $cache = json_decode($raw, true);
        if (!is_array($cache)) $cache = [];
    }
}

$all_changes = [];
$new_cache = [];

foreach ($SHEETS_TO_MONITOR as $key => $sheet_config) {
    $log_func("Checking sheet: {$sheet_config['label']} ($key)");
    
    $csv_data = fetch_sheet_csv($sheet_config['id'], $sheet_config['gid']);
    if ($csv_data === null) {
        $log_func("  Failed to fetch $key sheet, skipping.");
        // Preserve old cache for this sheet
        if (isset($cache[$key])) {
            $new_cache[$key] = $cache[$key];
        }
        continue;
    }
    
    $current_prices = parse_csv_prices($csv_data, $key);
    $log_func("  Parsed " . count($current_prices) . " price entries.");
    
    // Compare with cached prices
    $old_prices = isset($cache[$key]) ? $cache[$key] : [];
    $changes = detect_changes($old_prices, $current_prices, $sheet_config['label']);
    
    if (!empty($changes)) {
        $log_func("  Found " . count($changes) . " price changes!");
        $all_changes = array_merge($all_changes, $changes);
    } else {
        $log_func("  No changes detected.");
    }
    
    $new_cache[$key] = $current_prices;
}

// Save updated cache
file_put_contents($CACHE_FILE, json_encode($new_cache, JSON_PRETTY_PRINT));
$log_func("Cache updated.");

// Send notifications if there are changes
if (!empty($all_changes)) {
    $log_func("Sending notifications for " . count($all_changes) . " changes...");
    $result = send_spot_price_notification($all_changes);
    $log_func("Notification result: sent={$result['sent']}, failed={$result['failed']}");
} else {
    $log_func("No changes to notify.");
}

$log_func("Spot Price Monitor: Complete.");

if (!$is_cli) {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'changes' => count($all_changes),
        'details' => $all_changes,
    ]);
}

// ─── Helper Functions ────────────────────────────────────────────

/**
 * Fetch CSV data from a Google Sheet
 */
function fetch_sheet_csv($sheet_id, $gid) {
    $url = "https://docs.google.com/spreadsheets/d/{$sheet_id}/gviz/tq?tqx=out:csv&gid={$gid}";
    
    $context = stream_context_create([
        'http' => [
            'timeout' => 15,
            'header' => "Accept: text/csv\r\n",
        ],
    ]);
    
    $data = @file_get_contents($url, false, $context);
    if ($data === false) {
        return null;
    }
    return $data;
}

/**
 * Parse CSV into a normalized price map: ["key" => "price_string"]
 */
function parse_csv_prices($csv_data, $sheet_type) {
    $prices = [];
    $lines = str_getcsv_multiline($csv_data);
    
    if (count($lines) < 2) return $prices;
    
    $headers = $lines[0];
    
    switch ($sheet_type) {
        case 'non_ferrous':
            if (count($lines) < 2) break;
            $values = $lines[1]; // Row 2 contains the current prices
            
            // Map of config: [col_index, metal, subtype, city]
            $copy_mapping = [
                [0, 'Copper', 'Bhatti Scrap', 'Delhi'],
                [1, 'Copper', 'Plant Scrap', 'Bhiwadi'],
                [2, 'Copper', 'CC Rod', 'Delhi'], // CC ROD+
                [3, 'Copper', 'CC Rod', 'Delhi'], // CC ROD
                [4, 'Copper', 'Super D', 'Delhi'], // SUPER D+
                [5, 'Copper', 'Super D', 'Delhi'], // SUPER D
                [6, 'Copper', 'CCR 8mm', 'Bhiwadi'], // CCR+
                [7, 'Copper', 'CCR 8mm', 'Delhi'], // CCR
                [8, 'Copper', 'Zero Grade', 'Delhi'], // ZERO+
                [9, 'Copper', 'Zero Grade', 'Delhi'], // ZERO
                [10, 'Brass', 'Purja', 'Delhi'],
                [11, 'Brass', 'Honey', 'Delhi'],
                [12, 'Brass', 'Chadri', 'Delhi'],
                [13, 'Aluminium', 'Bartan', 'Delhi'],
                [14, 'Aluminium', 'Wire Scrap', 'Delhi'],
                [15, 'Aluminium', 'Company Ingot', 'Delhi'],
                [16, 'Aluminium', 'Company Rod', 'Delhi'],
                [17, 'Aluminium', 'Local Rod', 'Delhi'],
                [18, 'Lead', 'Hard/Soft', 'Delhi'],
                [19, 'Lead', 'Black', 'Delhi'],
                [20, 'Lead', 'White', 'Delhi'],
                [21, 'Lead', 'PP Grade', 'Delhi'],
                [22, 'Gun Metal', 'Local', 'Delhi'],
                [23, 'Gun Metal', 'Mix', 'Delhi'],
                [24, 'Gun Metal', 'Jalandhar', 'Delhi'],
                [25, 'Zinc', 'India HZL', 'Delhi'],
                [26, 'Zinc', 'Imported KZ', 'Delhi'],
                [27, 'Zinc', 'Australia', 'Delhi'],
                [28, 'Zinc', 'Zamak-3', 'Delhi'],
                [29, 'Zinc', 'Zamak-5', 'Delhi'],
                [30, 'Zinc', 'PMI', 'Delhi'],
                [31, 'Zinc', 'Dross', 'Delhi'],
                [32, 'Zinc', 'Tukadi (Big)', 'Delhi'],
                [33, 'Zinc', 'Tukadi (Mix)', 'Delhi'],
                [34, 'Zinc', 'Die Cast', 'Delhi'],
                [35, 'Nickel', 'Russian Cathode', 'Delhi'],
                [36, 'Nickel', 'Norway Cathode', 'Delhi'],
                [37, 'Tin', 'Indonesia', 'Delhi'],
            ];

            foreach ($copy_mapping as $map) {
                $idx = $map[0];
                $metal = $map[1];
                $subtype = $map[2];
                $city = strtoupper($map[3]);

                if ($idx < count($values)) {
                    $price_val = trim($values[$idx]);
                    if (!empty($price_val) && is_numeric_price($price_val)) {
                        $key = "{$city}|{$metal}|{$subtype}";
                        $prices[$key] = $price_val;
                    }
                }
            }
            break;
            
        case 'ferrous':
        case 'minor':
            for ($i = 1; $i < count($lines); $i++) {
                $row = $lines[$i];
                if (empty($row) || count($row) === 0) continue;
                
                $first_cell = trim(isset($row[0]) ? $row[0] : '');
                if (empty($first_cell)) continue;
                
                for ($col = 1; $col < count($row) && $col < count($headers); $col++) {
                    $price_val = trim(isset($row[$col]) ? $row[$col] : '');
                    if (!empty($price_val) && is_numeric_price($price_val)) {
                        $header = trim(isset($headers[$col]) ? $headers[$col] : "Col$col");
                        $key = "{$first_cell}|{$header}";
                        $prices[$key] = $price_val;
                    }
                }
            }
            break;
    }
    
    return $prices;
}

/**
 * Parse CSV respecting quoted fields with newlines
 */
function str_getcsv_multiline($csv_string) {
    $rows = [];
    $current_row = [];
    $current_cell = '';
    $in_quotes = false;
    
    $data = str_replace(["\r\n", "\r"], "\n", $csv_string);
    $len = strlen($data);
    
    for ($i = 0; $i < $len; $i++) {
        $char = $data[$i];
        
        if ($char === '"') {
            if ($in_quotes && $i + 1 < $len && $data[$i + 1] === '"') {
                $current_cell .= '"';
                $i++;
            } else {
                $in_quotes = !$in_quotes;
            }
        } elseif ($char === ',' && !$in_quotes) {
            $current_row[] = trim($current_cell);
            $current_cell = '';
        } elseif ($char === "\n" && !$in_quotes) {
            $current_row[] = trim($current_cell);
            $current_cell = '';
            // Check if row has any non-empty cells
            $has_content = false;
            foreach ($current_row as $c) {
                if ($c !== '') { $has_content = true; break; }
            }
            if ($has_content) {
                $rows[] = $current_row;
            }
            $current_row = [];
        } else {
            $current_cell .= $char;
        }
    }
    
    // Last row
    if (!empty($current_cell) || !empty($current_row)) {
        $current_row[] = trim($current_cell);
        $has_content = false;
        foreach ($current_row as $c) {
            if ($c !== '') { $has_content = true; break; }
        }
        if ($has_content) {
            $rows[] = $current_row;
        }
    }
    
    return $rows;
}

/**
 * Detect changes between old and new price maps
 */
function detect_changes($old_prices, $new_prices, $category_label) {
    $changes = [];
    
    foreach ($new_prices as $key => $new_val) {
        $old_val = isset($old_prices[$key]) ? $old_prices[$key] : null;
        
        // Only notify if price existed before AND changed (not first-time load)
        if ($old_val !== null && $old_val !== $new_val) {
            $old_num = parse_price_number($old_val);
            $new_num = parse_price_number($new_val);
            
            if ($old_num !== null && $new_num !== null && $old_num !== $new_num) {
                $parts = explode('|', $key);
                $changes[] = [
                    'key'       => $key,
                    'category'  => $category_label,
                    'city'      => isset($parts[0]) ? $parts[0] : '',
                    'item'      => implode(' ', array_slice($parts, 1)),
                    'old_price' => $old_val,
                    'new_price' => $new_val,
                    'direction' => $new_num > $old_num ? 'up' : 'down',
                ];
            }
        }
    }
    
    return $changes;
}

/**
 * Check if a string looks like a city name
 */
function is_city_name($str) {
    $cities = ['DELHI', 'MUMBAI', 'CHENNAI', 'KOLKATA', 'JAMNAGAR', 'BHIWADI', 
               'MORADABAD', 'AHMEDABAD', 'JAIPUR', 'HYDERABAD'];
    $clean = strtoupper(trim(str_replace('*', '', $str)));
    return in_array($clean, $cities);
}

/**
 * Check if a cell is a section header
 */
function is_section_header($cell) {
    $clean = strtoupper(trim(str_replace('*', '', $cell)));
    $keywords = ['COPPER', 'BRASS', 'ALUMINIUM', 'ALUMINUM', 'ZINC', 'LEAD', 
                 'NICKEL', 'TIN', 'GUN METAL', 'SCRAP'];
    foreach ($keywords as $kw) {
        if (strpos($clean, $kw) !== false) return true;
    }
    return false;
}

/**
 * Clean up section header names
 */
function clean_section_name($name) {
    return trim(str_replace('*', '', $name));
}

/**
 * Check if a string looks like a numeric price
 */
function is_numeric_price($str) {
    $cleaned = str_replace([',', ' ', '₹', 'Rs', '+', '-'], '', trim($str));
    return is_numeric($cleaned);
}

/**
 * Parse a price string to a float
 */
function parse_price_number($str) {
    $cleaned = str_replace([',', ' ', '₹', 'Rs', '+'], '', trim($str));
    // Handle "123/456" format → take first number
    if (strpos($cleaned, '/') !== false) {
        $parts = explode('/', $cleaned);
        $cleaned = $parts[0];
    }
    return is_numeric($cleaned) ? floatval($cleaned) : null;
}

/**
 * Ensure the notifications table exists
 */
function ensure_notifications_table() {
    $sql = "CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(50) NOT NULL DEFAULT 'price_alert',
        title VARCHAR(255) NOT NULL,
        message TEXT,
        data TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_type (type),
        INDEX idx_created (created_at)
    )";
    
    db_query($sql);
}

/**
 * Send spot price change notification to all users
 */
function send_spot_price_notification($changes) {
    if (empty($changes)) return ['sent' => 0, 'failed' => 0];
    
    // Group changes by city for a cleaner notification
    $by_city = [];
    foreach ($changes as $change) {
        $city = $change['city'] ? $change['city'] : 'Market';
        if (!isset($by_city[$city])) $by_city[$city] = [];
        $by_city[$city][] = $change;
    }
    
    // Build notification content
    $title = '📊 Spot Price Update';
    
    $body_parts = [];
    $first_city = '';
    $first_category = '';
    
    foreach ($by_city as $city => $city_changes) {
        if (empty($first_city)) {
            $first_city = $city;
            $first_category = isset($city_changes[0]['category']) ? $city_changes[0]['category'] : 'Non-Ferrous';
        }
        
        $count = count($city_changes);
        $details = [];
        $shown = array_slice($city_changes, 0, 2);
        foreach ($shown as $c) {
            $arrow = $c['direction'] === 'up' ? '↑' : '↓';
            $item_parts = explode('|', $c['item']);
            $item_short = trim(isset($item_parts[0]) ? $item_parts[0] : $c['item']);
            $details[] = "{$item_short}: ₹{$c['old_price']} → ₹{$c['new_price']} {$arrow}";
        }
        
        $city_display = ucfirst(strtolower($city));
        if ($count > 2) {
            $details[] = "+" . ($count - 2) . " more";
        }
        $body_parts[] = "{$city_display}: " . implode(', ', $details);
    }
    
    $body_shown = array_slice($body_parts, 0, 3);
    $body = implode(' | ', $body_shown);
    if (count($body_parts) > 3) {
        $body .= ' | +' . (count($body_parts) - 3) . ' more cities';
    }
    
    // FCM data payload for deep-linking
    $data = [
        'type'     => 'price_alert',
        'category' => $first_category,
        'city'     => $first_city,
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
    ];
    
    // Store notification in DB
    try {
        $changes_json = json_encode($changes);
        db_insert(
            "INSERT INTO notifications (type, title, message, data) VALUES (?, ?, ?, ?)",
            'ssss',
            ['price_alert', $title, $body, $changes_json]
        );
    } catch (Exception $e) {
        error_log("Failed to store notification: " . $e->getMessage());
    }
    
    // Send FCM to all users
    return send_push_to_all($title, $body, $data);
}
?>
