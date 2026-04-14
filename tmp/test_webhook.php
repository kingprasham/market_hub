<?php
/**
 * Test script for spot_price_monitor.php webhook
 */

$url = "https://mehrgrewal.com/markethub/api/spot_price_monitor.php?key=$key"; // Adjust as needed
$key = "mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC";

// Sample CSV for app_unified (Warehouse)
$csv_data = "LME WAREHOUSE STOCK REPORT,,,,,,,,,,,,,SETTLMENT,,,,,,,SBI,,,,,\n";
$csv_data .= "MARKET HUB,,,,,,,,,DATE,26-03-2026,,,DATE,METAL,CASH,,3M,,,USD/INR,EUR/INR,EUR/INR,GBP/INR\n";
$csv_data .= "SYMBOL,MT,IN,OUT,CHANGE,CHN %,C. WR,CHANGE,CHN %,LIVE-WR,CHANGE,CHN %,,,,BID,ASK,BID,ASK,,92.65,107.56,124.05,58.69\n";
$csv_data .= "COPPER,360175,950,50,900,0.25%,52700,100,0.19%,307475,800,0.26%,,25.03.2026,Copper,12133,12135,12234,12235\n";

$post_data = [
    'key' => $key,
    'sheet_type' => 'app_unified',
    'csv_data' => $csv_data
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($post_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

echo "Sending test webhook to $url...\n";
$response = curl_exec($ch);
if ($response === false) {
    echo "Error: " . curl_error($ch) . "\n";
} else {
    echo "Response: " . $response . "\n";
}
curl_close($ch);
