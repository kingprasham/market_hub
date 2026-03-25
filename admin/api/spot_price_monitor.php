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
    $cron_key = isset($_REQUEST['key']) ? $_REQUEST['key'] : '';
    $expected_key = 'mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC'; // Strong 40-char secret
    if ($cron_key !== $expected_key) {
        http_response_code(403);
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
}

define('ADMIN_PANEL', true);

// Manually set headers because config.php skips them when ADMIN_PANEL is defined
if (php_sapi_name() !== 'cli') {
    header('Access-Control-Allow-Origin: *');
    header('Content-Type: application/json; charset=utf-8');
}

require_once __DIR__ . '/config.php';

// ─── Configuration ───────────────────────────────────────────────
$CACHE_FILE = __DIR__ . '/spot_cache.json';
$LOG_FILE = __DIR__ . '/spot_monitor.log';

// Google Sheet IDs (same as in Flutter app)
$SHEETS_TO_MONITOR = [
    'non_ferrous' => [
        'id'    => '1VrCzC-sDcri5hO_TWfpHGx3ua7iaScLAtf-CFwQYBsI',
        'gid'   => '365100361',
        'label' => 'Non-Ferrous',
        'type'  => 'non_ferrous'
    ],
    'ferrous' => [
        'id'    => '1MGL9LrQn0M3WiHZYWnuGNukgqglezk3zWkzak2OXwg4',
        'gid'   => '0',
        'label' => 'Steel',
        'type'  => 'key_value'
    ],
    'minor' => [
        'id'    => '1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM',
        'gid'   => '1353908069',
        'label' => 'Minor and Ferro',
        'type'  => 'key_value'
    ],
    'app_tab' => [
        'id'    => '1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM',
        'gid'   => '914913757',
        'label' => 'App Update',
        'type'  => 'app_unified'
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
$new_cache = $cache; // Default to old cache

// INSTANT PUSH LOGIC (Google Apps Script)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['csv_data'], $_POST['sheet_type'])) {
    $log_func("Webhook triggered via direct POST push...");
    $sheet_type = $_POST['sheet_type'];
    $csv_data = trim($_POST['csv_data']);
    $sheet_key = '';
    $sheet_label = '';
    
    foreach ($SHEETS_TO_MONITOR as $key => $config) {
        if ($config['type'] === $sheet_type) {
            $sheet_key = $key;
            $sheet_label = $config['label'];
            break;
        }
    }
    
    if ($sheet_key) {
        $current_prices = parse_csv_prices($csv_data, $sheet_type);
        $log_func("  Parsed " . count($current_prices) . " price entries from POST.");
        
        $old_prices = isset($cache[$sheet_key]) ? $cache[$sheet_key] : [];
        $all_changes = detect_changes($old_prices, $current_prices, $sheet_label);
        
        if (!empty($all_changes)) {
            $log_func("  Found " . count($all_changes) . " price changes!");
        } else {
            $log_func("  No changes detected.");
        }
        
        if (count($current_prices) > 0) {
            $new_cache[$sheet_key] = $current_prices;
        }
    } else {
        $log_func("  Unknown sheet type: $sheet_type");
    }
} else {
    // FALLBACK GET / CRON LOGIC (1 pass)
    $all_changes = [];
    $new_cache = [];
    
    foreach ($SHEETS_TO_MONITOR as $key => $sheet_config) {
        $log_func("Checking sheet via GET/Cron: {$sheet_config['label']} ($key)");
        
        $csv_data = fetch_sheet_csv($sheet_config['id'], $sheet_config['gid']);
        if ($csv_data === null) {
            $log_func("  Failed to fetch $key sheet, skipping.");
            if (isset($cache[$key])) {
                $new_cache[$key] = $cache[$key];
            }
            continue;
        }
        
        $current_prices = parse_csv_prices($csv_data, $sheet_config['type']);
        $log_func("  Parsed " . count($current_prices) . " price entries.");
        
        $old_prices = isset($cache[$key]) ? $cache[$key] : [];
        $changes = detect_changes($old_prices, $current_prices, $sheet_config['label']);
        
        if (!empty($changes)) {
            $log_func("  Found " . count($changes) . " price changes!");
            $all_changes = array_merge($all_changes, $changes);
        } else {
            $log_func("  No changes detected.");
        }
        
        if (count($current_prices) === 0 && count($old_prices) > 0) {
            $new_cache[$key] = $old_prices;
        } else {
            $new_cache[$key] = $current_prices;
        }
    }
}

// Save updated cache atomically
$tmp_cache = $CACHE_FILE . '.tmp';
file_put_contents($tmp_cache, json_encode($new_cache, JSON_PRETTY_PRINT));
rename($tmp_cache, $CACHE_FILE);
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
    $time = time();
    $url = "https://docs.google.com/spreadsheets/d/{$sheet_id}/gviz/tq?tqx=out:csv&gid={$gid}&_cb={$time}";
    
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
            // Column mapping for cities on the FOR APP sheet
            $city_configs = [
                'DELHI' => [0, 1], 'MUMBAI' => [4, 5], 'HYDERABAD' => [7, 8],
                'AHMEDABAD' => [10, 11], 'PUNE' => [13, 14], 'CHENNAI' => [16, 17],
                'JODHPUR' => [19, 20], 'KOLKATA' => [22, 23], 'JAMNAGAR' => [25, 26],
                'JAGADHRI' => [28, 29], 'MORADABAD' => [31, 32], 'HATHRAS' => [34, 35],
                'JALANDHAR' => [37, 38], 'BME' => [40, 41]
            ];
            
            // Known metal subsection headers
            $known_metal_headers = ['COPPER', 'BRASS', 'ALUMINIUM', 'GUN METAL', 'ZINC', 'STEEL', 'NICKEL', 'TIN', 'LEAD', 'NICKEL CATHODE', 'BME MINOR METAL', 'MUMBAI MINOR METAL & FERRO'];
            
            // State tracking for each city's current subsection
            $current_categories = [];
            foreach ($city_configs as $city => $cols) {
                $current_categories[$city] = 'General';
            }

            // Start scanning downwards from row 1 (row 0 is just city headers)
            for ($i = 1; $i < count($lines); $i++) {
                $row = $lines[$i];
                if (empty($row) || count($row) === 0) continue;

                foreach ($city_configs as $city => $cols) {
                    $name_col = $cols[0];
                    $price1_col = $cols[1];
                    
                    if ($name_col < count($row)) {
                        $rawName = trim(isset($row[$name_col]) ? $row[$name_col] : '');
                        if (empty($rawName)) continue;
                        
                        $rawPrice = isset($row[$price1_col]) ? trim($row[$price1_col]) : '';
                        $price = parse_price_number($rawPrice);
                        
                        $cleanName = clean_section_name($rawName);
                        $upperName = strtoupper($cleanName);
                        
                        // Check if this row acts as a subsection header for this city
                        if (in_array($upperName, $known_metal_headers) && ($price === null || $price === 0)) {
                            $current_categories[$city] = ucwords(strtolower($cleanName));
                        } else if ($price !== null && $price > 0) {
                            // Valid price row
                            $subtype = $cleanName;
                            $cat = $current_categories[$city];
                            $prices["{$city}|{$cat} {$subtype}"] = $rawPrice;
                        }
                    }
                }
            }
            break;
            
        case 'key_value':
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

        case 'forex':
            // GID 0 in 1sOs... sheet
            // Rows are generally stable. We'll look for SBI and RBI rows.
            foreach ($lines as $row) {
                if (count($row) < 5) continue;
                $first = strtoupper(trim($row[0]));
                if (strpos($first, 'SBI') !== false) {
                    $prices['Forex|SBI USD'] = $row[1];
                    $prices['Forex|SBI EUR'] = $row[2];
                    $prices['Forex|SBI GBP'] = $row[3];
                    $prices['Forex|SBI JPY'] = $row[4];
                } else if (strpos($first, 'RBI') !== false) {
                    $prices['Forex|RBI USD'] = $row[1];
                    $prices['Forex|RBI GBP'] = $row[2];
                    $prices['Forex|RBI EUR'] = $row[3];
                    $prices['Forex|RBI JPY'] = $row[4];
                }
            }
            break;

        case 'app_unified':
            // GID 914913757 in 1sOs... sheet
            // This tab contains Warehouse (A-E), Settlement (N-S), and RBI/SBI (U-X)
            for ($i = 0; $i < count($lines); $i++) {
                $row = $lines[$i];
                if (empty($row)) continue;

                // 1. Warehouse section (Left side, Columns A-G)
                if (count($row) >= 5) {
                    $symbol = strtoupper(trim($row[0])); // Col A
                    if (in_array($symbol, ['COPPER', 'ALUMINIUM', 'ZINC', 'NICKEL', 'LEAD', 'TIN', 'AL. ALLOY', 'NASAAC', 'COBALT', 'CU', 'AL', 'ZN', 'PB', 'NI', 'SN', 'AA'])) {
                        $prices["Warehouse|{$symbol} MT"] = trim($row[1]);     // Col B
                        $prices["Warehouse|{$symbol} Change"] = trim($row[4]); // Col E
                    }
                }

                // 2. Settlement section (Middle-Right, Columns O-R / 14-17)
                if (count($row) >= 16) {
                    $metal = strtoupper(trim($row[14])); // Col O
                    if (in_array($metal, ['COPPER', 'TIN', 'LEAD', 'ZINC', 'ALUMINIUM', 'NICKEL', 'AL. ALLOY', 'NASAAC', 'COBALT'])) {
                        $prices["Settlement|{$metal} Ask"] = trim($row[16]); // Col Q (Ask)
                        $prices["Settlement|{$metal} 3M"] = trim($row[17]);  // Col R
                    }
                }

                // 3. Forex section (Far Right, Columns U-X / 20-23)
                // Layout: Row i: "SBI", Row i+1: "USD/INR"..., Row i+2: Prces
                if (count($row) >= 21) {
                    $label = strtoupper(trim($row[20])); // Col U
                    if ($label === 'SBI' && isset($lines[$i+2]) && count($lines[$i+2]) >= 21) {
                        $p_row = $lines[$i+2];
                        $prices['Forex|SBI USD'] = trim($p_row[20]); // Col U
                        $prices['Forex|SBI EUR'] = trim($p_row[21]); // Col V
                        $prices['Forex|SBI GBP'] = trim($p_row[22]); // Col W
                        $prices['Forex|SBI JPY'] = trim($p_row[23]); // Col X
                    } else if ($label === 'RBI' && isset($lines[$i+2]) && count($lines[$i+2]) >= 21) {
                        $p_row = $lines[$i+2];
                        $prices['Forex|RBI USD'] = trim($p_row[20]); // Col U
                        $prices['Forex|RBI GBP'] = trim($p_row[21]); // Col V
                        $prices['Forex|RBI EUR'] = trim($p_row[22]); // Col W
                        $prices['Forex|RBI JPY'] = trim($p_row[23]); // Col X
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
            
            // Round to 2 decimal places to avoid noise
            if ($old_num !== null && $new_num !== null && round($old_num, 2) !== round($new_num, 2)) {
                $parts = explode('|', $key);
                $city = isset($parts[0]) ? $parts[0] : '';
                
                // --- CATEGORY OVERRIDE ---
                // If it's a unified tab, the initial category might be generic (like 'LME Futures')
                // We override it based on the key prefix (Settlement, Warehouse, Forex)
                $override_label = $category_label;
                if ($city === 'Settlement') $override_label = 'LME Settlement';
                if ($city === 'Warehouse') $override_label = 'LME Warehouse';
                if ($city === 'Forex') $override_label = 'Forex';
                
                $changes[] = [
                    'key'       => $key,
                    'category'  => $override_label,
                    'city'      => $city,
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
 * Send change notification to all users
 */
function send_spot_price_notification($changes) {
    if (empty($changes)) return ['sent' => 0, 'failed' => 0];
    
    // Group changes by category (Non-Ferrous, Steel, Forex, etc.)
    $by_category = [];
    foreach ($changes as $change) {
        $cat = $change['category'];
        if (!isset($by_category[$cat])) $by_category[$cat] = [];
        $by_category[$cat][] = $change;
    }
    
    $results = ['sent' => 0, 'failed' => 0];
    
    foreach ($by_category as $cat_label => $cat_changes) {
        // If there are many changes in one category, it's likely a bulk update or noise
        // But if it's just a few, it's more relevant
        
        $title = "MH Spot Update";
        $body_parts = [];
        
        // Group by city within category (if applicable)
        $by_city = [];
        foreach ($cat_changes as $c) {
            $city = $c['city'] ? $c['city'] : 'Market';
            if (!isset($by_city[$city])) $by_city[$city] = [];
            $by_city[$city][] = $c;
        }
        
        foreach ($by_city as $city => $city_changes) {
            $count = count($city_changes);
            
            // Simplified notification body - just say "price updated"
            $details = [];
             foreach ($city_changes as $ch) {
                $arrow = $ch['direction'] === 'up' ? '↑' : '↓';
                
                // Clean item name
                $item_display = trim(str_replace($city, '', $ch['item']));
                $details[] = "{$item_display}: ₹{$ch['new_price']} {$arrow}";
            }
            
            $city_display = ($city !== 'Market' && $city !== 'Forex' && $city !== 'Settlement' && $city !== 'Warehouse') ? ucfirst(strtolower($city)) . ": " : "";
            $body_parts[] = $city_display . implode(', ', $details);
        }
        
        // Final body construction
        $body = "{$cat_label}: " . implode(' | ', $body_parts);
        if (strlen($body) > 180) {
            $body = substr($body, 0, 177) . '...';
        }
        
        // FCM data payload for deep-linking
        $first_change = $cat_changes[0];
        $type = 'price_alert';
        if ($cat_label === 'Forex') $type = 'forex_update';
        if ($cat_label === 'LME Futures') $type = 'futures_update';
        
        $data = [
            'type'         => $type,
            'category'     => $cat_label,
            'city'         => $first_change['city'],
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];
        
        // Store in DB
        try {
            $changes_json = json_encode($cat_changes);
            db_insert(
                "INSERT INTO notifications (type, title, message, data) VALUES (?, ?, ?, ?)",
                'ssss',
                [$type, $title, $body, $changes_json]
            );
        } catch (Exception $e) {
            error_log("Failed to store notification: " . $e->getMessage());
        }
        
        // Send push to all
        $res = send_push_to_all($title, $body, $data);
        $results['sent'] += $res['sent'];
        $results['failed'] += $res['failed'];
    }
    
    return $results;
}
/**
 * Ensure the notifications table exists and has required columns
 */
function ensure_notifications_table() {
    // Create notifications table if it doesn't exist
    db_query("CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(50) NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        data JSON DEFAULT NULL,
        read_status TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
}

/**
 * Clean section names for better categorization
 */
function clean_section_name($name) {
    return trim(str_replace([':', '*'], '', $name));
}

/**
 * Check if a string is a numeric price
 */
function is_numeric_price($str) {
    if (empty($str)) return false;
    $clean = str_replace([',', ' '], '', $str);
    return is_numeric($clean);
}

/**
 * Parse price string to float
 */
function parse_price_number($str) {
    if (empty($str)) return null;
    $clean = str_replace([',', ' '], '', $str);
    if (is_numeric($clean)) return floatval($clean);
    return null;
}

?>
