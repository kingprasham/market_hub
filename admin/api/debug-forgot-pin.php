<?php
/**
 * DEBUG: Test forgot-pin flow end-to-end
 * Access: https://mehrgrewal.com/markethub/api/debug-forgot-pin.php?email=YOUR_EMAIL
 * DELETE THIS FILE AFTER DEBUGGING
 */
header('Content-Type: text/html; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Forgot PIN Debug</h2>";

// Use same config as all other API endpoints
define('ADMIN_PANEL', true);
require_once 'config.php';

$email = $_GET['email'] ?? '';

echo "<h3>1. Database Column Check</h3>";
try {
    $cols = ['pin_reset_otp', 'pin_reset_otp_expires', 'pin_reset_token', 'pin_reset_token_expires'];
    foreach ($cols as $col) {
        $result = db_fetch_one("SHOW COLUMNS FROM users LIKE '$col'");
        echo $result ? "✅ $col column exists<br>" : "❌ $col column MISSING<br>";
    }
} catch (Exception $e) {
    echo "❌ DB Error: " . $e->getMessage() . "<br>";
}

if (!empty($email)) {
    echo "<h3>2. User Lookup: $email</h3>";
    try {
        $user = db_fetch_one("SELECT id, full_name, status, pin_reset_otp, pin_reset_otp_expires FROM users WHERE email = ?", 's', [$email]);
        if ($user) {
            echo "✅ User found: ID={$user['id']}, Name={$user['full_name']}, Status={$user['status']}<br>";
            echo "Current OTP in DB: <b>" . ($user['pin_reset_otp'] ?? 'NULL') . "</b><br>";
            echo "OTP Expires: " . ($user['pin_reset_otp_expires'] ?? 'NULL') . "<br>";
            
            if (!empty($user['pin_reset_otp_expires'])) {
                $expired = strtotime($user['pin_reset_otp_expires']) < time();
                echo $expired ? "⚠️ OTP is EXPIRED<br>" : "✅ OTP is still valid<br>";
            }
        } else {
            echo "❌ No user found with email: $email<br>";
        }
    } catch (Exception $e) {
        echo "❌ Error: " . $e->getMessage() . "<br>";
    }

    echo "<h3>3. Test Email Sending</h3>";
    try {
        $server_host = $_SERVER['HTTP_HOST'] ?? 'markethub.app';
        $server_host = preg_replace('/:\d+$/', '', $server_host);
        $from_email = 'noreply@' . $server_host;
        
        echo "From: $from_email<br>";
        echo "To: $email<br>";
        echo "PHP mail() exists: " . (function_exists('mail') ? 'Yes' : 'No') . "<br>";
        
        $subject = "Market Hub - Test Email";
        $body = "<html><body><p>Test email from Market Hub. If you see this, email works.</p></body></html>";
        $headers  = "MIME-Version: 1.0\r\n";
        $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
        $headers .= "From: Market Hub <$from_email>\r\n";
        
        $sent = @mail($email, $subject, $body, $headers);
        echo $sent ? "✅ mail() returned TRUE (email queued)<br>" : "❌ mail() returned FALSE (email failed)<br>";
    } catch (Exception $e) {
        echo "❌ Email Error: " . $e->getMessage() . "<br>";
    }

    echo "<h3>4. Test OTP Flow Simulation</h3>";
    if (isset($user) && $user) {
        try {
            // Generate test OTP
            $test_otp = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $test_expires = date('Y-m-d H:i:s', strtotime('+15 minutes'));
            
            $updated = db_query(
                "UPDATE users SET pin_reset_otp = ?, pin_reset_otp_expires = ? WHERE id = ?",
                'ssi',
                [$test_otp, $test_expires, $user['id']]
            );
            echo "Save OTP to DB: " . ($updated ? "✅ Success" : "❌ Failed") . "<br>";
            
            // Read back
            $check = db_fetch_one("SELECT pin_reset_otp, pin_reset_otp_expires FROM users WHERE id = ?", 'i', [$user['id']]);
            echo "Read back OTP: <b>" . ($check['pin_reset_otp'] ?? 'NULL') . "</b><br>";
            echo "Read back Expires: " . ($check['pin_reset_otp_expires'] ?? 'NULL') . "<br>";
            
            // Test verification
            $match = ($check['pin_reset_otp'] === $test_otp);
            echo "OTP Match Test: " . ($match ? "✅ Match" : "❌ Mismatch") . "<br>";
            
            echo "<br><b>➡️ Use this OTP in the app to test: <span style='font-size:24px;color:green;'>$test_otp</span></b><br>";
            echo "<i>(Valid for 15 minutes)</i><br>";
        } catch (Exception $e) {
            echo "❌ OTP Flow Error: " . $e->getMessage() . "<br>";
        }
    }
} else {
    echo "<p>Add <code>?email=your@email.com</code> to the URL to test.</p>";
}

echo "<hr><p style='color:red;'><b>⚠️ DELETE THIS FILE AFTER DEBUGGING</b></p>";
