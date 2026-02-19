<?php
/**
 * Market Hub Admin - News Management (English)
 */
$page_title = 'News (English)';
require_once 'includes/header.php';

$action = $_GET['action'] ?? 'list';
$edit_id = intval($_GET['id'] ?? 0);

// Get plans for targeting
$plans = db_fetch_all("SELECT * FROM plans WHERE is_active = 1 ORDER BY price");

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('news.php', 'error', 'Invalid request');
    }
    
    $form_action = $_POST['form_action'] ?? '';
    
    if ($form_action === 'save') {
        $id = intval($_POST['id'] ?? 0);
        $title = trim($_POST['title'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $supporting_link = trim($_POST['supporting_link'] ?? '');
        $target_plans = $_POST['target_plans'] ?? ['all'];
        $is_active = isset($_POST['is_active']) ? 1 : 0;
        
        // Validation
        if (empty($title)) {
            set_flash('error', 'Title is required');
        } else {
            // Handle file uploads
            $image_path = $_POST['existing_image'] ?? '';
            $pdf_path = $_POST['existing_pdf'] ?? '';
            
            if (!empty($_FILES['image']['name'])) {
                $upload = upload_file($_FILES['image'], 'news', 'image');
                if ($upload['success']) {
                    // Delete old image
                    if ($image_path) delete_file($image_path);
                    $image_path = $upload['path'];
                } else {
                    set_flash('error', 'Image upload failed: ' . $upload['error']);
                }
            }
            
            if (!empty($_FILES['pdf']['name'])) {
                $upload = upload_file($_FILES['pdf'], 'news', 'pdf');
                if ($upload['success']) {
                    // Delete old PDF
                    if ($pdf_path) delete_file($pdf_path);
                    $pdf_path = $upload['path'];
                } else {
                    set_flash('error', 'PDF upload failed: ' . $upload['error']);
                }
            }
            
            $target_json = json_encode($target_plans);
            
            if ($id) {
                // Update
                db_query(
                    "UPDATE news SET title = ?, description = ?, image_path = ?, pdf_path = ?, supporting_link = ?, target_plans = ?, is_active = ?, updated_at = NOW() WHERE id = ?",
                    'ssssssii',
                    [$title, $description, $image_path, $pdf_path, $supporting_link, $target_json, $is_active, $id]
                );
                redirect('news.php', 'success', 'News updated successfully');
            } else {
                // Insert
                $news_id = db_insert(
                    "INSERT INTO news (title, description, image_path, pdf_path, supporting_link, target_plans, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    'ssssssi',
                    [$title, $description, $image_path, $pdf_path, $supporting_link, $target_json, $is_active]
                );
                
                // Send push notification to all users
                if ($news_id && $is_active) {
                    send_content_notification('news', $title, $news_id, $target_plans);
                }
                
                redirect('news.php', 'success', 'News added successfully');
            }
        }
    }
    
    if ($form_action === 'delete') {
        $id = intval($_POST['id'] ?? 0);
        $news = db_fetch_one("SELECT * FROM news WHERE id = ?", 'i', [$id]);
        if ($news) {
            delete_file($news['image_path']);
            delete_file($news['pdf_path']);
            db_query("DELETE FROM news WHERE id = ?", 'i', [$id]);
            redirect('news.php', 'success', 'News deleted successfully');
        }
    }
}

// Get news for editing
$edit_item = null;
if ($action === 'edit' && $edit_id) {
    $edit_item = db_fetch_one("SELECT * FROM news WHERE id = ?", 'i', [$edit_id]);
    if (!$edit_item) {
        redirect('news.php', 'error', 'News not found');
    }
}

// Get all news for list
$news_list = db_fetch_all("SELECT * FROM news ORDER BY created_at DESC");
?>

<?php if ($action === 'add' || $action === 'edit'): ?>
<!-- Add/Edit Form -->
<div class="card">
    <div class="card-header">
        <i class="bi bi-<?= $action === 'edit' ? 'pencil' : 'plus-circle' ?> me-2"></i>
        <?= $action === 'edit' ? 'Edit News' : 'Add News' ?>
    </div>
    <div class="card-body">
    <div class="card-body">
        <form method="POST" enctype="multipart/form-data" onsubmit="return uploadWithProgress(this, 'uploadProgress', this.querySelector('button[type=submit]'))">
            <?= csrf_field() ?>
            <input type="hidden" name="form_action" value="save">
            <input type="hidden" name="id" value="<?= $edit_item['id'] ?? '' ?>">
            <input type="hidden" name="existing_image" value="<?= $edit_item['image_path'] ?? '' ?>">
            <input type="hidden" name="existing_pdf" value="<?= $edit_item['pdf_path'] ?? '' ?>">
            
            <!-- Progress Bar -->
            <div id="uploadProgress" class="progress mb-3 d-none" style="height: 25px;">
                <div class="progress-bar progress-bar-striped progress-bar-animated bg-primary" role="progressbar" style="width: 0%;">0%</div>
            </div>

            <div class="row">
                <div class="col-md-8">
                    <div class="mb-3">
                        <label class="form-label">Title *</label>
                        <input type="text" name="title" class="form-control" required
                               value="<?= e($edit_item['title'] ?? '') ?>">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="6"><?= e($edit_item['description'] ?? '') ?></textarea>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Supporting Link</label>
                        <input type="url" name="supporting_link" class="form-control" placeholder="https://..."
                               value="<?= e($edit_item['supporting_link'] ?? '') ?>">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Target Plans</label>
                        <div>
                            <?php
                            $current_targets = $edit_item ? json_decode($edit_item['target_plans'], true) : ['all'];
                            ?>
                            <div class="form-check form-check-inline">
                                <input type="checkbox" name="target_plans[]" value="all" class="form-check-input" id="plan_all"
                                       <?= in_array('all', $current_targets) ? 'checked' : '' ?>>
                                <label class="form-check-label" for="plan_all">All Plans</label>
                            </div>
                            <?php foreach ($plans as $plan): ?>
                            <div class="form-check form-check-inline">
                                <input type="checkbox" name="target_plans[]" value="<?= $plan['id'] ?>" class="form-check-input" id="plan_<?= $plan['id'] ?>"
                                       <?= in_array($plan['id'], $current_targets) ? 'checked' : '' ?>>
                                <label class="form-check-label" for="plan_<?= $plan['id'] ?>"><?= e($plan['name']) ?></label>
                            </div>
                            <?php endforeach; ?>
                        </div>
                    </div>
                    
                    <div class="form-check mb-3">
                        <input type="checkbox" name="is_active" class="form-check-input" id="is_active"
                               <?= ($edit_item['is_active'] ?? true) ? 'checked' : '' ?>>
                        <label class="form-check-label" for="is_active">Active (visible to users)</label>
                    </div>
                </div>
                
                <div class="col-md-4">
                    <div class="mb-3">
                        <label class="form-label">Image</label>
                        <input type="file" name="image" class="form-control" accept="image/*"
                               onchange="previewFile(this, 'imagePreview')">
                        <div id="imagePreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['image_path'])): ?>
                            <img src="<?= file_url($edit_item['image_path']) ?>" class="img-fluid rounded" style="max-height: 150px;">
                            <?php endif; ?>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">PDF</label>
                        <input type="file" name="pdf" class="form-control" accept=".pdf"
                               onchange="previewFile(this, 'pdfPreview')">
                        <div id="pdfPreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['pdf_path'])): ?>
                            <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 48px;"></i>
                            <br><small><?= basename($edit_item['pdf_path']) ?></small>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
            
            <hr>
            
            <div class="d-flex justify-content-between">
                <a href="news.php" class="btn btn-secondary">
                    <i class="bi bi-arrow-left me-2"></i>Cancel
                </a>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-check-lg me-2"></i>Save News
                </button>
            </div>
        </form>
    </div>
</div>

<?php else: ?>
<!-- News List -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="mb-0">All News</h5>
    <a href="news.php?action=add" class="btn btn-primary">
        <i class="bi bi-plus-circle me-2"></i>Add News
    </a>
</div>

<div class="card">
    <div class="card-body">
        <?php if (empty($news_list)): ?>
        <div class="empty-state">
            <i class="bi bi-newspaper"></i>
            <p>No news articles yet</p>
            <a href="news.php?action=add" class="btn btn-primary">Add First News</a>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table datatable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Attachments</th>
                        <th>Target Plans</th>
                        <th>Status</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($news_list as $item): ?>
                    <tr>
                        <td><?= $item['id'] ?></td>
                        <td><strong><?= e(truncate($item['title'], 50)) ?></strong></td>
                        <td>
                            <?php if ($item['image_path']): ?>
                                <a href="<?= file_url($item['image_path']) ?>" target="_blank" title="View Image">
                                    <i class="bi bi-image text-success me-2"></i>
                                </a>
                            <?php endif; ?>
                            <?php if ($item['pdf_path']): ?>
                                <a href="<?= file_url($item['pdf_path']) ?>" target="_blank" title="View PDF">
                                    <i class="bi bi-file-pdf text-danger"></i>
                                </a>
                            <?php endif; ?>
                            <?php if (!$item['image_path'] && !$item['pdf_path']): ?>-<?php endif; ?>
                        </td>
                        <td><?= format_target_plans($item['target_plans']) ?></td>
                        <td><?= status_badge($item['is_active'] ? 'active' : 'inactive') ?></td>
                        <td><?= format_date($item['created_at'], 'd M Y') ?></td>
                        <td class="action-btns">
                            <a href="news.php?action=edit&id=<?= $item['id'] ?>" class="btn btn-sm btn-outline-primary" title="Edit">
                                <i class="bi bi-pencil"></i>
                            </a>
                            <form method="POST" class="d-inline" onsubmit="return confirmDelete('Delete this news?')">
                                <?= csrf_field() ?>
                                <input type="hidden" name="form_action" value="delete">
                                <input type="hidden" name="id" value="<?= $item['id'] ?>">
                                <button type="submit" class="btn btn-sm btn-outline-danger" title="Delete">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<?php require_once 'includes/footer.php'; ?>
