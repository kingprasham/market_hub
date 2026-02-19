<?php
/**
 * Market Hub Admin - Settings Management
 */
$page_title = 'Settings';
require_once 'includes/header.php';

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('settings.php', 'error', 'Invalid request');
    }
    
    // Update each setting
    $settings = [
        'terms_conditions' => $_POST['terms_conditions'] ?? '',
        'about_us' => $_POST['about_us'] ?? '',
        'contact_phone' => $_POST['contact_phone'] ?? '',
        'contact_email' => $_POST['contact_email'] ?? '',
        'contact_whatsapp' => $_POST['contact_whatsapp'] ?? '',
        'contact_address' => $_POST['contact_address'] ?? '',
        'firebase_server_key' => $_POST['firebase_server_key'] ?? '',
        'firebase_service_account' => $_POST['firebase_service_account'] ?? '',
    ];
    
    foreach ($settings as $key => $value) {
        $exists = db_fetch_one("SELECT id FROM settings WHERE setting_key = ?", 's', [$key]);
        if ($exists) {
            db_query("UPDATE settings SET setting_value = ?, updated_at = NOW() WHERE setting_key = ?", 'ss', [$value, $key]);
        } else {
            db_insert("INSERT INTO settings (setting_key, setting_value) VALUES (?, ?)", 'ss', [$key, $value]);
        }
    }
    
    redirect('settings.php', 'success', 'Settings saved successfully');
}

// Get current settings
$settings_raw = db_fetch_all("SELECT * FROM settings");
$settings = [];
foreach ($settings_raw as $row) {
    $settings[$row['setting_key']] = $row['setting_value'];
}
?>

<form method="POST">
    <?= csrf_field() ?>
    
    <div class="row">
        <div class="col-lg-6 mb-4">
            <div class="card h-100">
                <div class="card-header">
                    <i class="bi bi-telephone me-2"></i>Contact Information
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label">Phone Number</label>
                        <input type="text" name="contact_phone" class="form-control" 
                               value="<?= e($settings['contact_phone'] ?? '') ?>" placeholder="+91 9876543210">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">WhatsApp Number</label>
                        <input type="text" name="contact_whatsapp" class="form-control" 
                               value="<?= e($settings['contact_whatsapp'] ?? '') ?>" placeholder="+91 9876543210">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Email Address</label>
                        <input type="email" name="contact_email" class="form-control" 
                               value="<?= e($settings['contact_email'] ?? '') ?>" placeholder="support@example.com">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Address</label>
                        <textarea name="contact_address" class="form-control" rows="2"><?= e($settings['contact_address'] ?? '') ?></textarea>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-lg-6 mb-4">
            <div class="card h-100">
                <div class="card-header">
                    <i class="bi bi-bell me-2"></i>Push Notifications (Firebase)
                </div>
                <div class="card-body">
                    <div class="alert alert-info small">
                        <strong>Recommended:</strong> Use Firebase V1 API with Service Account JSON.
                        <br>Get it from: Firebase Console → Project Settings → Service accounts → Generate new private key
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Firebase Service Account JSON (V1 API - Recommended)</label>
                        <textarea name="firebase_service_account" class="form-control font-monospace" rows="6" 
                                  placeholder='Paste the entire JSON file content here'><?= e($settings['firebase_service_account'] ?? '') ?></textarea>
                    </div>
                    
                    <hr>
                    <p class="text-muted small mb-2">Or use Legacy API (deprecated):</p>
                    
                    <div class="mb-3">
                        <label class="form-label">Firebase Server Key (Legacy)</label>
                        <input type="text" name="firebase_server_key" class="form-control" 
                               value="<?= e($settings['firebase_server_key'] ?? '') ?>" 
                               placeholder="Legacy server key (deprecated)">
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="card mb-4">
        <div class="card-header">
            <i class="bi bi-info-circle me-2"></i>About Us
        </div>
        <div class="card-body">
            <textarea name="about_us" class="form-control" rows="6"><?= e($settings['about_us'] ?? '') ?></textarea>
            <small class="text-muted">HTML is supported. This content is shown in the app's About Us section.</small>
        </div>
    </div>
    
    <div class="card mb-4">
        <div class="card-header">
            <i class="bi bi-file-text me-2"></i>Terms & Conditions
        </div>
        <div class="card-body">
            <textarea name="terms_conditions" class="form-control" rows="10"><?= e($settings['terms_conditions'] ?? '') ?></textarea>
            <small class="text-muted">HTML is supported. This content is shown in the app's Terms & Conditions section.</small>
        </div>
    </div>
    
    <div class="text-end">
        <button type="submit" class="btn btn-primary btn-lg">
            <i class="bi bi-check-lg me-2"></i>Save Settings
        </button>
    </div>
</form>

<?php require_once 'includes/footer.php'; ?>
