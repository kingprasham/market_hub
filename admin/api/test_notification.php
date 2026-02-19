<?php
// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>FCM Notification Debugger</h1>";

// 1. Check requirements
echo "<h2>1. Checking Requirements</h2>";
echo "PHP Version: " . phpversion() . "<br>";
echo "OpenSSL Extension: " . (extension_loaded('openssl') ? '<span style="color:green">Enabled</span>' : '<span style="color:red">DISABLED</span>') . "<br>";
echo "cURL Extension: " . (extension_loaded('curl') ? '<span style="color:green">Enabled</span>' : '<span style="color:red">DISABLED</span>') . "<br>";

// 2. Load Config
echo "<h2>2. Loading Configuration</h2>";
define('ADMIN_PANEL', true); // Prevent CORS headers for this HTML page
try {
    require_once 'config.php';
    echo "Config loaded successfully.<br>";
} catch (Exception $e) {
    die("Failed to load config.php: " . $e->getMessage());
}

// 3. Check Service Account
echo "<h2>3. Checking Service Account Credentials</h2>";
$service_account_json = get_setting('firebase_service_account');

if (empty($service_account_json)) {
    echo "Database setting 'firebase_service_account' is empty.<br>";
    // Manually trigger the fallback logic from config.php by calling a dummy function or just checking logic
    // We'll mimic the fallback logic here to verify it matches
    echo "Using Hardcoded Fallback...<br>";
    $service_account_json = '{
  "type": "service_account",
  "project_id": "market-hub-58dca",
  "private_key_id": "03722d3d8672c046d78eee11ea116a213baacc1a",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQD16C/dE7BLvqQ4\nT03EefA99vz1xugEzoprj3jtaq/ZOxQMl6eSp1lyL+1S36tN8678gcf7YJy/aKtJ\nDjIVa4xtHQERBl4O5sZKCheRLa6lU/0hKRIIuP/NuoxMKJlGucHi+NDeLBegTFob\nNf7KNfhG94kxz6VK0zxqiX2fQdgzaLHIQebzFIKuts5d5J1KgMcvc4AEJYNPQ+88\nr7XYwcSVRtmKuhFWy8CzjiSZ/zscLWnv1NPnA80cBKQSVB0sEeRnIZMTO3gyEQ66\nTGweqm6hwgE+3hAuuvusK6HBxw3on0vV7zli0kTnjij1AsMQiASjOFes4BPXrxvd\nd1Q+ANOJAgMBAAECggEAP4e2geu5wr/khmW6pjWIo0Ghtc+nFsLTkRlWeSP0fW9d\nbSlrEiDpI26NZjlB9RgtT7Ap3eBmbq8YfX3M46rO80uogGEAQOJPPUahMxE1yyHJ\nRl1petZsxBZbc7uTaenI1R5KO/PxQKkpKFmJU22hEJiYGcXXIt8y/yU5TsFAnXr/\nuaMPKJIN4OuWPTsH4e1Mn2En6G6u02SOWWExVpdhzRE+GpgL5vmdoGT0MLu7Ov/C\n8qKUKTkZTEpKCORIVMKo/hQNHxnOrm+3ohlVckPGYRS4lFwDiJc3lmcznT6DG1kq\n4E1gvPTMIt2i4An7Z3hAwG+alpujmbL5UV02SbyeDwKBgQD8wU98NTKJesswQDF+\nTrUiO0etkw8k1NBl8tmH1tKkFV71twR0TA9Nd44iQHMR39XiakmOAQhLpTw3tvWa\n8nMA95lsnia+AivQQxEhqtmeSZ9s8JwOCpFDm4iqM2XrZFqcZPK6e49J1j0YzStH\n3BSZkzZmf2WwKHrQ4m4FhTRowwKBgQD5EF6rfXY5LML++8Jj6FdXrn7DvngH+iOt\nfG8qY796i8oOXH7ZixRwHpsk4WZNQUlDw5pGYKzeGreqacYD3mNjbaQmIzVnhCTt\nZX00ZhVnA8Xewv0Kj7ansEBbEz4HboeOexMsuuRnwtNv4jeqmTTbXoECEh2O/WMp\n8kgVF/5twwKBgDJWXXojLhlrNyQ45KJ/Elvq6m+LJizzpT1ojCIdin3bM7pD5MM0\nkqee89OmekRJC9O3z0ZUtk46bi+6ZFejiXvb09Zp+NVGoWsssDDAUe7QQsvzb2Ds\ngdmxFBqxec7Tgag8AotZKERQQoK5+bCqCAA97Uuke6AFr9ACCF9ZFAL5AoGARCXi\ngXHWw1YoFLS2P7f3DhrEvLKFDUm4MWP21tZsMg/FvaA5ZTTU5si5EqJJ56GRdmUy\n9UbGhg8xagN/FtfmwfHiFD1WA3j40awPUiMMgB9cKNOZgSZJiCCFu2XMdyQbGzU5\nzedlT67TQ63WJWu+Nrfo/LQQOmvCkluktYDXMRkCgYA7dWi5WUWs2RMEHAAbaLrO\n7E/Ruz3rkbYsvj1nKU2YaaiBxupFFG0fFg1SgdcdnjNQTsuH5sfGnSzatGtJMys4\nxSD8Yzv8UUsPSyB70U33mB6LVPsWlQws5McWNfW7F6WL1VTOOnUeoUECBMFDLIYz\n0aCA0WZEPtDSB3zXax8nnQ==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@market-hub-58dca.iam.gserviceaccount.com",
  "client_id": "112989263646484850552",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40market-hub-58dca.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}';
} else {
    echo "Found credentials in database.<br>";
}

$sa = json_decode($service_account_json, true);
if (!$sa) {
    die('<span style="color:red">FAILED: JSON decode error on credentials.</span>');
}
echo "Project ID: " . ($sa['project_id'] ?? 'MISSING') . "<br>";
echo "Client Email: " . ($sa['client_email'] ?? 'MISSING') . "<br>";
echo "Private Key: " . (isset($sa['private_key']) ? 'Present (' . strlen($sa['private_key']) . ' chars)' : 'MISSING') . "<br>";

// 4. Test OAuth Token Generation
echo "<h2>4. Testing Access Token Generation</h2>";
$access_token = get_firebase_access_token($sa);

if ($access_token) {
    echo "<span style='color:green'>SUCCESS: Access Token Generated</span><br>";
    echo "Token length: " . strlen($access_token) . " chars<br>";
} else {
    echo "<span style='color:red'>FAILED: Could not generate access token.</span><br>";
    echo "Check OpenSSL signing and Google OAuth endpoint reachability.<br>";
}

// 5. Fetch Test User
echo "<h2>5. Fetching Target User</h2>";
$user = db_fetch_one("SELECT id, full_name, fcm_token FROM users WHERE fcm_token IS NOT NULL AND fcm_token != '' LIMIT 1");

if (!$user) {
    die('<span style="color:red">FAILED: No users found with FCM token. Please Login to the app first.</span>');
}

echo "Found User: " . $user['id'] . " (" . $user['full_name'] . ")<br>";
echo "Token: " . substr($user['fcm_token'], 0, 20) . "...<br>";

// 6. Sending Test Notification
echo "<h2>6. Sending Test Notification</h2>";
if ($access_token) {
    echo "Sending via <strong>FCM V1 API</strong>...<br>";
    // Pass valid string data map
    $test_data = ['test_key' => 'test_value', 'timestamp' => strval(time())];
    $result = send_fcm_v1($user['fcm_token'], "Test Notification", "This is a test from the debugger.", $test_data, $service_account_json);
    
    echo "<h3>Response:</h3>";
    echo "<pre>";
    print_r($result);
    echo "</pre>";
    
    if (isset($result['name'])) {
        echo "<h3 style='color:green'>SUCCESS! Notification Sent. Check your phone.</h3>";
    } else {
        echo "<h3 style='color:red'>FAILED. Check error response above.</h3>";
    }
} else {
    echo "Skipping send due to missing access token.<br>";
}
?>
