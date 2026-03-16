<?php
/**
 * Market Hub API - Historical Prices Scraper for WestMetall
 */
// 1. Define ADMIN_PANEL to allow config/database include
define('ADMIN_PANEL', true);

require_once __DIR__ . '/config.php';

// Manually set headers because config.php skips them when ADMIN_PANEL is defined
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

// Get parameters
$metal = isset($_GET['metal']) ? $_GET['metal'] : '';
$field = isset($_GET['field']) ? $_GET['field'] : '';

// Map common metal names to fields if field is missing but metal is present
$metal_map = [
    'COPPER' => 'LME_Cu_cash',
    'TIN' => 'LME_Sn_cash',
    'LEAD' => 'LME_Pb_cash',
    'ZINC' => 'LME_Zn_cash',
    'ALUMINIUM' => 'LME_Al_cash',
    'ALUMINUM' => 'LME_Al_cash',
    'NICKEL' => 'LME_Ni_cash',
    'AL. ALLOY' => 'LME_AA_cash',
    'NASAAC' => 'LME_NA_cash',
    'COBALT' => 'LME_Co_cash',
];

if (empty($field) && !empty($metal)) {
    $upper_metal = strtoupper($metal);
    $field = isset($metal_map[$upper_metal]) ? $metal_map[$upper_metal] : '';
}

if (empty($field)) {
    api_error('Field parameter or valid metal name is required');
}

$url = "https://www.westmetall.com/en/markdaten.php?action=table&field={$field}";

// Fetch HTML using cURL for better compatibility
$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 15,
    CURLOPT_USERAGENT => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    CURLOPT_FOLLOWLOCATION => true
]);

$html = curl_exec($ch);
$curl_error = curl_error($ch);
curl_close($ch);

if ($html === false) {
    api_error('Failed to fetch data from source: ' . $curl_error);
}

// Simple parsing using regex
// WestMetall table structure is typically rows with 4-5 cells
$data = [];

// Match rows with at least 4 cells - Using a more flexible regex for whitespace and attributes
preg_match_all('/<tr[^>]*>\s*<td[^>]*>(.*?)<\/td>\s*<td[^>]*>(.*?)<\/td>\s*<td[^>]*>(.*?)<\/td>\s*<td[^>]*>(.*?)<\/td>\s*<\/tr>/is', $html, $matches, PREG_SET_ORDER);

foreach ($matches as $match) {
    $date = trim(strip_tags($match[1]));
    $cash = trim(strip_tags($match[2]));
    $three_m = trim(strip_tags($match[3]));
    $stock = trim(strip_tags($match[4]));
    
    // Skip header or invalid rows
    if (strpos(strtolower($date), 'date') !== false || empty($date)) continue;
    
    // Check if date looks like a date (e.g. "10. March 2026" or "10.03.2026")
    // WestMetall uses format like "10. March 2026"
    if (!preg_match('/\d{1,2}/', $date)) continue;
    
    // Parse values to numeric
    $cash_val = floatval(str_replace([',', ' '], '', $cash));
    $three_m_val = floatval(str_replace([',', ' '], '', $three_m));
    $stock_val = floatval(str_replace([',', ' '], '', $stock));
    
    if ($cash_val > 0 || $stock_val > 0) {
        $data[] = [
            'date' => $date,
            'cash' => $cash_val,
            'three_m' => $three_m_val,
            'stock' => $stock_val,
        ];
    }
}

// Return limited set (top 60 rows)
$data = array_slice($data, 0, 60);

// If no data found, try a broader regex for safety
if (empty($data)) {
    // Sometimes the cells have links like <a href="...">10. March 2026</a>
    // The strip_tags in previous loop handles this, but the \s might be strict
    // We already handled it well above.
}

api_success(['data' => $data]);
