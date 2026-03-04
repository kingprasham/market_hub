<?php
/**
 * Market Hub Admin - Ads Management
 */
$page_title = 'Manage Ads';
require_once 'includes/header.php';

$action = $_GET['action'] ?? 'list';
$edit_id = intval($_GET['id'] ?? 0);

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('ads.php', 'error', 'Invalid request');
    }
    
    $form_action = $_POST['form_action'] ?? '';
    
    if ($form_action === 'save') {
        $id = intval($_POST['id'] ?? 0);
        $title = trim($_POST['title'] ?? '');
        $subtitle = trim($_POST['subtitle'] ?? '');
        $company_name = trim($_POST['company_name'] ?? '');
        $heading = trim($_POST['heading'] ?? '');
        $disclaimer = trim($_POST['disclaimer'] ?? '');
        
        // Build JSON arrays from simple inputs
        $ad_desc = trim($_POST['ad_description'] ?? '');
        $contact_num = trim($_POST['contact_number'] ?? '');
        
        $info_obj = [];
        if (!empty($ad_desc)) {
            $info_obj[] = [
                'title' => 'Description',
                'description' => $ad_desc,
                'iconName' => 'info'
            ];
        }
        $info_items = json_encode($info_obj);
        
        $contact_obj = [];
        if (!empty($contact_num)) {
            $clean_num = str_replace(array(' ', '-', '(', ')'), '', $contact_num);
            $contact_obj[] = [
                'type' => 'phone',
                'label' => $contact_num,
                'uri' => 'tel:' . $clean_num
            ];
        }
        $contacts = json_encode($contact_obj);
        $sort_order = intval($_POST['sort_order'] ?? 0);
        $is_active = isset($_POST['is_active']) ? 1 : 0;
        
        if (empty($title)) {
            set_flash('error', 'Title is required');
        } else {
            $image_path = $_POST['existing_image'] ?? '';
            
            if (!empty($_FILES['image']['name'])) {
                $upload = upload_file($_FILES['image'], 'ads', 'image');
                if ($upload['success']) {
                    if ($image_path) delete_file($image_path);
                    $image_path = $upload['path'];
                } else {
                    $image_path = $_POST['existing_image'] ?? ''; // fallback
                }
            }
            
            if ($id) {
                db_query(
                    "UPDATE ads SET title = ?, subtitle = ?, company_name = ?, heading = ?, image_path = ?, info_items = ?, contacts = ?, disclaimer = ?, is_active = ?, sort_order = ?, updated_at = NOW() WHERE id = ?",
                    'ssssssssiii',
                    [$title, $subtitle, $company_name, $heading, $image_path, $info_items, $contacts, $disclaimer, $is_active, $sort_order, $id]
                );
                redirect('ads.php', 'success', 'Ad modified successfully');
            } else {
                db_insert(
                    "INSERT INTO ads (title, subtitle, company_name, heading, image_path, info_items, contacts, disclaimer, is_active, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    'ssssssssii',
                    [$title, $subtitle, $company_name, $heading, $image_path, $info_items, $contacts, $disclaimer, $is_active, $sort_order]
                );
                redirect('ads.php', 'success', 'Ad added successfully');
            }
        }
    }
    
    if ($form_action === 'delete') {
        $id = intval($_POST['id'] ?? 0);
        $ad = db_fetch_one("SELECT * FROM ads WHERE id = ?", 'i', [$id]);
        if ($ad) {
            if ($ad['image_path']) {
                delete_file($ad['image_path']);
            }
            db_query("DELETE FROM ads WHERE id = ?", 'i', [$id]);
            redirect('ads.php', 'success', 'Ad deleted successfully');
        }
    }
}

$edit_item = null;
if ($action === 'edit' && $edit_id) {
    $edit_item = db_fetch_one("SELECT * FROM ads WHERE id = ?", 'i', [$edit_id]);
    if (!$edit_item) redirect('ads.php', 'error', 'Ad not found');
}

$ads_list = db_fetch_all("SELECT * FROM ads ORDER BY sort_order ASC, created_at DESC");
$ads_list = db_fetch_all("SELECT * FROM ads ORDER BY sort_order ASC, created_at DESC");

// Extract description and contact for existing edit items
$existing_desc = '';
$existing_contact = '';
if ($action === 'edit' && $edit_item) {
    $info_arr = json_decode($edit_item['info_items'] ?? '[]', true);
    if (is_array($info_arr) && !empty($info_arr) && isset($info_arr[0]['description'])) {
        $existing_desc = $info_arr[0]['description'];
    }
    
    $contact_arr = json_decode($edit_item['contacts'] ?? '[]', true);
    if (is_array($contact_arr) && !empty($contact_arr) && isset($contact_arr[0]['label'])) {
        $existing_contact = $contact_arr[0]['label'];
    }
}
?>

<?php if ($action === 'add' || $action === 'edit'): ?>
<div class="card">
    <div class="card-header">
        <i class="bi bi-<?= $action === 'edit' ? 'pencil' : 'plus-circle' ?> me-2"></i>
        <?= $action === 'edit' ? 'Edit Ad' : 'Add New Ad' ?>
    </div>
    <div class="card-body">
        <form method="POST" enctype="multipart/form-data" onsubmit="return uploadWithProgress(this, 'uploadProgress', this.querySelector('button[type=submit]'))">
            <?= csrf_field() ?>
            <input type="hidden" name="form_action" value="save">
            <input type="hidden" name="id" value="<?= $edit_item['id'] ?? '' ?>">
            <input type="hidden" name="existing_image" value="<?= $edit_item['image_path'] ?? '' ?>">
            
            <!-- Progress Bar -->
            <div id="uploadProgress" class="progress mb-3 d-none" style="height: 25px;">
                <div class="progress-bar progress-bar-striped progress-bar-animated bg-primary" role="progressbar" style="width: 0%;">0%</div>
            </div>

            <div class="row">
                <div class="col-md-8">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Carousel Title *</label>
                            <input type="text" name="title" class="form-control" required value="<?= e($edit_item['title'] ?? '') ?>">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Carousel Subtitle</label>
                            <input type="text" name="subtitle" class="form-control" value="<?= e($edit_item['subtitle'] ?? '') ?>">
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Company Name</label>
                            <input type="text" name="company_name" class="form-control" value="<?= e($edit_item['company_name'] ?? 'MARKET HUB') ?>">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Details Heading</label>
                            <input type="text" name="heading" class="form-control" value="<?= e($edit_item['heading'] ?? '') ?>">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Ad Description</label>
                        <textarea name="ad_description" class="form-control" rows="4"><?= e($existing_desc) ?></textarea>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Contact Number <small class="text-muted">(Optional)</small></label>
                        <input type="text" name="contact_number" class="form-control" value="<?= e($existing_contact) ?>">
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Disclaimer</label>
                        <input type="text" name="disclaimer" class="form-control" value="<?= e($edit_item['disclaimer'] ?? 'This Is A Paid Advertisement, Market Hub Is Not Responsible For Any Profit Or Loss') ?>">
                    </div>

                    <div class="row">
                        <div class="col-md-6 form-check mb-3 ms-2">
                            <input type="checkbox" name="is_active" class="form-check-input" id="is_active" <?= ($edit_item['is_active'] ?? true) ? 'checked' : '' ?>>
                            <label class="form-check-label" for="is_active">Active (visible in app)</label>
                        </div>
                        <div class="col-md-5 mb-3">
                            <label class="form-label">Sort Order</label>
                            <input type="number" name="sort_order" class="form-control" value="<?= e($edit_item['sort_order'] ?? '0') ?>">
                        </div>
                    </div>
                </div>
                
                <div class="col-md-4">
                    <div class="mb-3">
                        <label class="form-label">Image (Ratio: ~16:9)</label>
                        <input type="file" name="image" class="form-control" accept="image/*" onchange="previewFile(this, 'imagePreview')">
                        <div id="imagePreview" class="mt-2 text-center">
                            <?php if (!empty($edit_item['image_path'])): ?>
                            <img src="<?= file_url($edit_item['image_path']) ?>" class="img-fluid rounded" style="max-height: 200px;">
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
            
            <hr>
            <div class="d-flex justify-content-between">
                <a href="ads.php" class="btn btn-secondary"><i class="bi bi-arrow-left me-2"></i>Cancel</a>
                <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-2"></i>Save Ad</button>
            </div>
        </form>
    </div>
</div>

<?php else: ?>
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="mb-0">Manage Advertisements</h5>
    <a href="ads.php?action=add" class="btn btn-primary"><i class="bi bi-plus-circle me-2"></i>Add New Ad</a>
</div>

<div class="card">
    <div class="card-body">
        <?php if (empty($ads_list)): ?>
        <div class="empty-state">
            <i class="bi bi-badge-ad"></i>
            <p>No advertisements yet</p>
            <a href="ads.php?action=add" class="btn btn-primary">Add First Ad</a>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table datatable">
                <thead>
                    <tr>
                        <th>Order</th>
                        <th>Image</th>
                        <th>Title</th>
                        <th>Company</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($ads_list as $item): ?>
                    <tr>
                        <td><?= $item['sort_order'] ?></td>
                        <td>
                            <?php if ($item['image_path']): ?>
                                <img src="<?= file_url($item['image_path']) ?>" class="rounded" style="height: 40px; width: auto;" alt="Ad Image">
                            <?php else: ?>
                                <span class="text-muted">No image</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <strong><?= e(truncate($item['title'], 40)) ?></strong>
                            <br><small class="text-muted"><?= e(truncate($item['subtitle'], 40)) ?></small>
                        </td>
                        <td><?= e($item['company_name']) ?></td>
                        <td><?= status_badge($item['is_active'] ? 'active' : 'inactive') ?></td>
                        <td class="action-btns">
                            <a href="ads.php?action=edit&id=<?= $item['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="bi bi-pencil"></i></a>
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
