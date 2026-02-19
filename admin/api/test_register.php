<?php
/**
 * Test Registration - Use this to test the registration API
 * DELETE AFTER TESTING!
 */
define('ADMIN_PANEL', true);

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Test Registration</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        input, button { display: block; width: 100%; padding: 10px; margin: 10px 0; }
        button { background: #007bff; color: white; border: none; cursor: pointer; }
        #result { background: #f5f5f5; padding: 15px; margin-top: 20px; white-space: pre-wrap; }
    </style>
</head>
<body>
    <h2>Test Registration API</h2>
    <form id="testForm">
        <input type="text" name="full_name" placeholder="Full Name" value="Test User" required>
        <input type="email" name="email" placeholder="Email" value="test@example.com" required>
        <input type="text" name="phone" placeholder="Phone (10 digits)" value="9876543210" required>
        <input type="text" name="whatsapp" placeholder="WhatsApp (optional)">
        <button type="submit">Test Register</button>
    </form>
    <div id="result">Results will appear here...</div>
    
    <script>
        document.getElementById('testForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            const formData = new FormData(this);
            const result = document.getElementById('result');
            result.textContent = 'Sending request...';
            
            try {
                const response = await fetch('register.php', {
                    method: 'POST',
                    body: formData
                });
                const text = await response.text();
                result.textContent = 'Status: ' + response.status + '\n\nResponse:\n' + text;
                
                try {
                    const json = JSON.parse(text);
                    result.textContent += '\n\nParsed JSON:\n' + JSON.stringify(json, null, 2);
                } catch(e) {}
            } catch(err) {
                result.textContent = 'Error: ' + err.message;
            }
        });
    </script>
</body>
</html>
