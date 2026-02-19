<?php
/**
 * Market Hub Admin - Home Updates Management
 */
$page_title = 'Home Updates';
require_once 'includes/header.php';

$action = $_GET['action'] ?? 'list';
$edit_id = intval($_GET['id'] ?? 0);

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('home_updates.php', 'error', 'Invalid request');
    }
    
    $form_action = $_POST['form_action'] ?? '';
    
    if ($form_action === 'save') {
        $id = intval($_POST['id'] ?? 0);
        $title = trim($_POST['title'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $is_active = isset($_POST['is_active']) ? 1 : 0;
        
        if (empty($title)) {
            set_flash('error', 'Title is required');
        } else {
            $image_path = $_POST['existing_image'] ?? '';
            $pdf_path = $_POST['existing_pdf'] ?? '';
            
            if (!empty($_FILES['image']['name'])) {
                $upload = upload_file($_FILES['image'], 'home_updates', 'image');
                if ($upload['success']) {
                    if ($image_path) delete_file($image_path);
                    $image_path = $upload['path'];
                }
            }
            
            if (!empty($_FILES['pdf']['name'])) {
                $upload = upload_file($_FILES['pdf'], 'home_updates', 'pdf');
                if ($upload['success']) {
                    if ($pdf_path) delete_file($pdf_path);
                    $pdf_path = $upload['path'];
                }
            }
            
            if ($id) {
                db_query(
                    "UPDATE home_updates SET title = ?, description = ?, image_path = ?, pdf_path = ?, is_active = ?, updated_at = NOW() WHERE id = ?",
                    'ssssii',
                    [$title, $description, $image_path, $pdf_path, $is_active, $id]
                );
                redirect('home_updates.php', 'success', 'Update modified successfully');
            } else {
                $update_id = db_insert(
                    "INSERT INTO home_updates (title, description, image_path, pdf_path, is_active) VALUES (?, ?, ?, ?, ?)",
                    'ssssi',
                    [$title, $description, $image_path, $pdf_path, $is_active]
                );
                
                // Send push notification to all users
                if ($update_id && $is_active) {
                    send_content_notification('home_update', $title, $update_id, null);
                }
                
                redirect('home_updates.php', 'success', 'Update added successfully');
            }
        }
    }
    
    if ($form_action === 'delete') {
        $id = intval($_POST['id'] ?? 0);
        $update = db_fetch_one("SELECT * FROM home_updates WHERE id = ?", 'i', [$id]);
        if ($update) {
            delete_file($update['image_path']);
            delete_file($update['pdf_path']);
            db_query("DELETE FROM home_updates WHERE id = ?", 'i', [$id]);
            redirect('home_updates.php', 'success', 'Update deleted successfully');
        }
    }
}

$edit_item = null;
if ($action === 'edit' && $edit_id) {
    $edit_item = db_fetch_one("SELECT * FROM home_updates WHERE id = ?", 'i', [$edit_id]);
    if (!$edit_item) redirect('home_updates.php', 'error', 'Update not found');
}

$updates_list = db_fetch_all("SELECT * FROM home_updates ORDER BY created_at DESC");
?>

<?php if ($action === 'add' || $action === 'edit'): ?>
<div class="card">
    <div class="card-header">
        <i class="bi bi-<?= $action === 'edit' ? 'pencil' : 'plus-circle' ?> me-2"></i>
        <?= $action === 'edit' ? 'Edit Home Update' : 'Add Home Update' ?>
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
                        <input type="text" name="title" class="form-control" required value="<?= e($edit_item['title'] ?? '') ?>">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="6"><?= e($edit_item['description'] ?? '') ?></textarea>
                        <small class="text-muted">This will be shown to all users on the Home page</small>
                    </div>
                    
                    <div class="form-check mb-3">
                        <input type="checkbox" name="is_active" class="form-check-input" id="is_active"
                               <?= ($edit_item['is_active'] ?? true) ? 'checked' : '' ?>>
                        <label class="form-check-label" for="is_active">Active (visible on Home page)</label>
                    </div>
                </div>
                
                <div class="col-md-4">
                    <div class="mb-3">
                        <label class="form-label">Image (Optional)</label>
                        <input type="file" name="image" class="form-control" accept="image/*" onchange="previewFile(this, 'imagePreview')">
                        <div id="imagePreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['image_path'])): ?>
                            <img src="<?= file_url($edit_item['image_path']) ?>" class="img-fluid rounded" style="max-height: 150px;">
                            <?php endif; ?>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">PDF (Optional)</label>
                        <input type="file" name="pdf" class="form-control" accept=".pdf" onchange="previewFile(this, 'pdfPreview')">
                        <div id="pdfPreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['pdf_path'])): ?>
                            <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 48px;"></i>
                            <br><a href="<?= file_url($edit_item['pdf_path']) ?>" target="_blank" class="btn btn-sm btn-outline-primary mt-2">View</a>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
            
            <hr>
            <div class="d-flex justify-content-between">
                <a href="home_updates.php" class="btn btn-secondary"><i class="bi bi-arrow-left me-2"></i>Cancel</a>
                <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-2"></i>Save Update</button>
            </div>
        </form>
    </div>
</div>

<?php else: ?>
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="mb-0">All Home Updates</h5>
    <a href="home_updates.php?action=add" class="btn btn-primary"><i class="bi bi-plus-circle me-2"></i>Add Update</a>
</div>

<div class="card">
    <div class="card-body">
        <?php if (empty($updates_list)): ?>
        <div class="empty-state">
            <i class="bi bi-house"></i>
            <p>No home updates yet</p>
            <a href="home_updates.php?action=add" class="btn btn-primary">Add First Update</a>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table datatable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Attachments</th>
                        <th>Status</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($updates_list as $item): ?>
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
                        <td><?= status_badge($item['is_active'] ? 'active' : 'inactive') ?></td>
                        <td><?= format_date($item['created_at'], 'd M Y') ?></td>
                        <td class="action-btns">
                            <a href="home_updates.php?action=edit&id=<?= $item['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="bi bi-pencil"></i></a>
                            <form method="POST" class="d-inline" onsubmit="return confirmDelete()">
                                <?= csrf_field() ?>
                                <input type="hidden" name="form_action" value="delete">
                                <input type="hidden" name="id" value="<?= $item['id'] ?>">
                                <button type="submit" class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
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
