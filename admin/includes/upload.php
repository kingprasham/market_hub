<?php
/**
 * Market Hub Admin - Secure File Upload Handler
 */

// Prevent direct access
if (!defined('ADMIN_PANEL')) {
    die('Direct access not allowed');
}

// Upload directories
define('UPLOAD_BASE', __DIR__ . '/../uploads/');
define('MAX_IMAGE_SIZE', 5 * 1024 * 1024);  // 5MB
define('MAX_PDF_SIZE', 10 * 1024 * 1024);   // 10MB

// Allowed file types
$allowed_images = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
$allowed_docs = ['pdf'];

/**
 * Upload a file securely
 * 
 * @param array $file $_FILES['field_name']
 * @param string $directory Subdirectory (e.g., 'news', 'circulars')
 * @param string $type 'image' or 'pdf'
 * @return array ['success' => bool, 'path' => string, 'error' => string]
 */
function upload_file($file, $directory, $type = 'image') {
    global $allowed_images, $allowed_docs;
    
    // Check for upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'error' => get_upload_error($file['error'])];
    }
    
    // Get file info
    $original_name = $file['name'];
    $tmp_path = $file['tmp_name'];
    $size = $file['size'];
    $extension = strtolower(pathinfo($original_name, PATHINFO_EXTENSION));
    
    // Validate extension
    $allowed = $type === 'image' ? $allowed_images : $allowed_docs;
    if (!in_array($extension, $allowed)) {
        return ['success' => false, 'error' => 'Invalid file type. Allowed: ' . implode(', ', $allowed)];
    }
    
    // Validate size
    $max_size = $type === 'image' ? MAX_IMAGE_SIZE : MAX_PDF_SIZE;
    if ($size > $max_size) {
        return ['success' => false, 'error' => 'File too large. Max: ' . format_size($max_size)];
    }
    
    // Validate MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $tmp_path);
    finfo_close($finfo);
    
    $valid_mimes = $type === 'image' 
        ? ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        : ['application/pdf'];
    
    if (!in_array($mime, $valid_mimes)) {
        return ['success' => false, 'error' => 'Invalid file content'];
    }
    
    // For images, validate with getimagesize
    if ($type === 'image') {
        $image_info = @getimagesize($tmp_path);
        if ($image_info === false) {
            return ['success' => false, 'error' => 'Invalid image file'];
        }
    }
    
    // Create upload directory if not exists
    $upload_dir = UPLOAD_BASE . $directory . '/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    // Generate unique filename
    $new_filename = uniqid() . '_' . time() . '.' . $extension;
    $destination = $upload_dir . $new_filename;
    
    // Move file
    if (!move_uploaded_file($tmp_path, $destination)) {
        return ['success' => false, 'error' => 'Failed to save file'];
    }
    
    // Return relative path for database storage
    $relative_path = 'uploads/' . $directory . '/' . $new_filename;
    
    return ['success' => true, 'path' => $relative_path];
}

/**
 * Delete uploaded file
 */
function delete_file($path) {
    if (empty($path)) return true;
    
    $full_path = __DIR__ . '/../' . $path;
    if (file_exists($full_path)) {
        return unlink($full_path);
    }
    return true;
}

/**
 * Get upload error message
 */
function get_upload_error($code) {
    $errors = [
        UPLOAD_ERR_INI_SIZE => 'File exceeds server limit',
        UPLOAD_ERR_FORM_SIZE => 'File exceeds form limit',
        UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
        UPLOAD_ERR_NO_FILE => 'No file was uploaded',
        UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
        UPLOAD_ERR_CANT_WRITE => 'Failed to write to disk',
        UPLOAD_ERR_EXTENSION => 'Upload blocked by extension',
    ];
    return $errors[$code] ?? 'Unknown upload error';
}

/**
 * Get file URL for display
 */
function file_url($path) {
    if (empty($path)) return '';
    return base_url($path);
}

/**
 * Check if file exists
 */
function file_exists_upload($path) {
    if (empty($path)) return false;
    return file_exists(__DIR__ . '/../' . $path);
}
