<?php
/**
 * Market Hub Admin - Circulars Management
 */
$page_title = 'Circulars';
require_once 'includes/header.php';

$action = $_GET['action'] ?? 'list';
$edit_id = intval($_GET['id'] ?? 0);
$plans = db_fetch_all("SELECT * FROM plans WHERE is_active = 1 ORDER BY price");

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('circulars.php', 'error', 'Invalid request');
    }
    
    $form_action = $_POST['form_action'] ?? '';
    
    if ($form_action === 'save') {
        $id = intval($_POST['id'] ?? 0);
        $title = trim($_POST['title'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $target_plans = $_POST['target_plans'] ?? ['all'];
        $is_active = isset($_POST['is_active']) ? 1 : 0;
        
        if (empty($title)) {
            set_flash('error', 'Title is required');
        } else {
            $image_path = $_POST['existing_image'] ?? '';
            $pdf_path = $_POST['existing_pdf'] ?? '';
            
            if (!empty($_FILES['image']['name'])) {
                $upload = upload_file($_FILES['image'], 'circulars', 'image');
                if ($upload['success']) {
                    if ($image_path) delete_file($image_path);
                    $image_path = $upload['path'];
                }
            }
            
            if (!empty($_FILES['pdf']['name'])) {
                $upload = upload_file($_FILES['pdf'], 'circulars', 'pdf');
                if ($upload['success']) {
                    if ($pdf_path) delete_file($pdf_path);
                    $pdf_path = $upload['path'];
                }
            }
            
            $target_json = json_encode($target_plans);
            
            if ($id) {
                db_query(
                    "UPDATE circulars SET title = ?, description = ?, image_path = ?, pdf_path = ?, target_plans = ?, is_active = ?, updated_at = NOW() WHERE id = ?",
                    'sssssii',
                    [$title, $description, $image_path, $pdf_path, $target_json, $is_active, $id]
                );
                redirect('circulars.php', 'success', 'Circular updated successfully');
            } else {
                $circular_id = db_insert(
                    "INSERT INTO circulars (title, description, image_path, pdf_path, target_plans, is_active) VALUES (?, ?, ?, ?, ?, ?)",
                    'sssssi',
                    [$title, $description, $image_path, $pdf_path, $target_json, $is_active]
                );
                
                // Send push notification to all users
                if ($circular_id && $is_active) {
                    send_content_notification('circular', $title, $circular_id, $target_plans);
                }
                
                redirect('circulars.php', 'success', 'Circular added successfully');
            }
        }
    }
    
    if ($form_action === 'delete') {
        $id = intval($_POST['id'] ?? 0);
        $circular = db_fetch_one("SELECT * FROM circulars WHERE id = ?", 'i', [$id]);
        if ($circular) {
            delete_file($circular['image_path']);
            delete_file($circular['pdf_path']);
            db_query("DELETE FROM circulars WHERE id = ?", 'i', [$id]);
            redirect('circulars.php', 'success', 'Circular deleted successfully');
        }
    }
}

$edit_item = null;
if ($action === 'edit' && $edit_id) {
    $edit_item = db_fetch_one("SELECT * FROM circulars WHERE id = ?", 'i', [$edit_id]);
    if (!$edit_item) redirect('circulars.php', 'error', 'Circular not found');
}

$circular_list = db_fetch_all("SELECT * FROM circulars ORDER BY created_at DESC");
?>

<?php if ($action === 'add' || $action === 'edit'): ?>
<div class="card">
    <div class="card-header">
        <i class="bi bi-<?= $action === 'edit' ? 'pencil' : 'plus-circle' ?> me-2"></i>
        <?= $action === 'edit' ? 'Edit Circular' : 'Add Circular' ?>
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
                        <textarea name="description" class="form-control" rows="4"><?= e($edit_item['description'] ?? '') ?></textarea>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Target Plans</label>
                        <div>
                            <?php $current_targets = $edit_item ? json_decode($edit_item['target_plans'], true) : ['all']; ?>
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
                        <label class="form-check-label" for="is_active">Active</label>
                    </div>
                </div>
                
                <div class="col-md-4">
                    <div class="mb-3">
                        <label class="form-label">PDF (Primary) *</label>
                        <input type="file" name="pdf" class="form-control" accept=".pdf" onchange="previewFile(this, 'pdfPreview')"
                               <?= $action === 'add' ? 'required' : '' ?>>
                        <div id="pdfPreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['pdf_path'])): ?>
                            <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 48px;"></i>
                            <br><small><?= basename($edit_item['pdf_path']) ?></small>
                            <br><a href="<?= file_url($edit_item['pdf_path']) ?>" target="_blank" class="btn btn-sm btn-outline-primary mt-2">View PDF</a>
                            <?php endif; ?>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Cover Image (Optional)</label>
                        <input type="file" name="image" class="form-control" accept="image/*" onchange="previewFile(this, 'imagePreview')">
                        <div id="imagePreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['image_path'])): ?>
                            <img src="<?= file_url($edit_item['image_path']) ?>" class="img-fluid rounded" style="max-height: 150px;">
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
            
            <hr>
            <div class="d-flex justify-content-between">
                <a href="circulars.php" class="btn btn-secondary"><i class="bi bi-arrow-left me-2"></i>Cancel</a>
                <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-2"></i>Save Circular</button>
            </div>
        </form>
    </div>
</div>

<?php else: ?>
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="mb-0">All Circulars</h5>
    <a href="circulars.php?action=add" class="btn btn-primary"><i class="bi bi-plus-circle me-2"></i>Add Circular</a>
</div>

<div class="card">
    <div class="card-body">
        <?php if (empty($circular_list)): ?>
        <div class="empty-state">
            <i class="bi bi-file-earmark-pdf"></i>
            <p>No circulars yet</p>
            <a href="circulars.php?action=add" class="btn btn-primary">Add First Circular</a>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table datatable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>PDF</th>
                        <th>Target Plans</th>
                        <th>Status</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($circular_list as $item): ?>
                    <tr>
                        <td><?= $item['id'] ?></td>
                        <td><strong><?= e(truncate($item['title'], 50)) ?></strong></td>
                        <td>
                            <?php if ($item['pdf_path']): ?>
                            <a href="<?= file_url($item['pdf_path']) ?>" target="_blank" class="btn btn-sm btn-outline-danger">
                                <i class="bi bi-file-pdf me-1"></i>View
                            </a>
                            <?php else: ?>
                            -
                            <?php endif; ?>
                        </td>
                        <td><?= format_target_plans($item['target_plans']) ?></td>
                        <td><?= status_badge($item['is_active'] ? 'active' : 'inactive') ?></td>
                        <td><?= format_date($item['created_at'], 'd M Y') ?></td>
                        <td class="action-btns">
                            <a href="circulars.php?action=edit&id=<?= $item['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="bi bi-pencil"></i></a>
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
