<?php
/**
 * Market Hub API - User Registration
 * POST /api/register.php
 */

// 1. Manually set Headers FIRST to ensure JSON response even on crash
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// 2. Handle Preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 3. Define ADMIN_PANEL for dependencies
define('ADMIN_PANEL', true);

// 4. Define Logging Helper locally
define('DEBUG_LOG_FILE', __DIR__ . '/../uploads/debug_log.txt');
function safe_log($msg) {
    try {
        $ts = date('Y-m-d H:i:s');
        @file_put_contents(DEBUG_LOG_FILE, "[$ts] $msg" . PHP_EOL, FILE_APPEND);
    } catch (Throwable $t) {}
}

// 5. Global Try-Catch wrapper
try {
    // Include Config (which enables error handler!)
    // If this throws, it will be caught by global catch below
    require_once 'config.php';

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Method not allowed'); // Will be caught
    }

    // Get Data
    $data = get_json_input();
    if (empty($data)) {
        $data = $_POST;
    }

    // Validate
    $full_name = trim($data['full_name'] ?? '');
    $email = trim(strtolower($data['email'] ?? ''));
    $phone = trim($data['phone'] ?? '');
    $whatsapp = trim($data['whatsapp'] ?? '');
    $plan_id = intval($data['plan_id'] ?? 0);
    $fcm_token = trim($data['fcm_token'] ?? '');

    if (empty($full_name)) throw new Exception('Full name is required');
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) throw new Exception('Valid email is required');
    if (empty($phone) || strlen($phone) < 10) throw new Exception('Valid phone number is required');

    // DB: Check Existing
    $existing = db_fetch_one("SELECT id, status FROM users WHERE email = ?", 's', [$email]);
    if ($existing) {
        if ($existing['status'] === 'rejected') {
             db_query("DELETE FROM users WHERE id = ?", 'i', [$existing['id']]);
        } else {
             throw new Exception('Email already registered. Please login.');
        }
    }

    // File Upload
    $visiting_card_path = '';
    if (isset($_FILES['visiting_card']) && $_FILES['visiting_card']['error'] === UPLOAD_ERR_OK) {
        require_once __DIR__ . '/../includes/upload.php';
        $upload = upload_file($_FILES['visiting_card'], 'visiting_cards', 'image');
        if ($upload['success']) {
            $visiting_card_path = $upload['path'];
        } else {
             safe_log("Upload Error: " . $upload['error']);
             // Continue without card
        }
    }

    // Insert
    $otp = generate_otp(6);
    $otp_expires = date('Y-m-d H:i:s', strtotime('+15 minutes'));
    $plan_id_value = $plan_id > 0 ? $plan_id : null;

    $user_id = db_insert(
        "INSERT INTO users (full_name, email, phone, whatsapp, plan_id, visiting_card, fcm_token, email_otp, otp_expires_at, status) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')",
        'ssssissss',
        [$full_name, $email, $phone, $whatsapp, $plan_id_value, $visiting_card_path, $fcm_token, $otp, $otp_expires]
    );

    if (!$user_id) throw new Exception('Database insert returned no ID');

    // Email
    $email_subject = "Market Hub - Verification: $otp";
    $email_body = "<h1>Code: $otp</h1>"; 
    $from_email = 'noreply@' . $_SERVER['HTTP_HOST'];
    $headers = "MIME-Version: 1.0\r\nContent-Type: text/html\r\nFrom: Market Hub <$from_email>\r\n";

    $mail_sent = false;
    try {
        $mail_sent = mail($email, $email_subject, $email_body, $headers);
    } catch (Throwable $e) {
        safe_log("Mail Error: " . $e->getMessage());
    }

    // Success Response
    echo json_encode([
        'success' => true,
        'message' => 'Registration successful. verify email.',
        'user_id' => $user_id,
        'email' => $email,
        'otp_sent' => $mail_sent, // Can check this in client
        'debug_otp' => $otp
    ]);

} catch (Throwable $e) {
    // Catch ANY error, including require errors, DB errors, validation errors
    safe_log("Fatal Register Error: " . $e->getMessage());
    
    // Force 200 OK (or 400) but definitely JSON
    http_response_code(400); 
    echo json_encode([
        'success' => false, 
        'error' => $e->getMessage()
    ]);
}
