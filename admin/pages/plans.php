<?php
/**
 * Market Hub Admin - Plans Management
 */
$page_title = 'Plan Management';
require_once 'includes/header.php';

$action = $_GET['action'] ?? 'list';
$edit_id = intval($_GET['id'] ?? 0);

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('plans.php', 'error', 'Invalid request');
    }
    
    $form_action = $_POST['form_action'] ?? '';
    
    if ($form_action === 'save') {
        $id = intval($_POST['id'] ?? 0);
        $name = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $price = floatval($_POST['price'] ?? 0);
        $duration_months = intval($_POST['duration_months'] ?? 1);
        $features_text = trim($_POST['features'] ?? '');
        $is_active = isset($_POST['is_active']) ? 1 : 0;
        
        // Convert features to JSON array
        $features_array = array_filter(array_map('trim', explode("\n", $features_text)));
        $features_json = json_encode(array_values($features_array));
        
        if (empty($name)) {
            set_flash('error', 'Plan name is required');
        } else {
            if ($id) {
                db_query(
                    "UPDATE plans SET name = ?, description = ?, price = ?, duration_months = ?, features = ?, is_active = ?, updated_at = NOW() WHERE id = ?",
                    'ssdisii',
                    [$name, $description, $price, $duration_months, $features_json, $is_active, $id]
                );
                redirect('plans.php', 'success', 'Plan updated successfully');
            } else {
                db_insert(
                    "INSERT INTO plans (name, description, price, duration_months, features, is_active) VALUES (?, ?, ?, ?, ?, ?)",
                    'ssdisi',
                    [$name, $description, $price, $duration_months, $features_json, $is_active]
                );
                redirect('plans.php', 'success', 'Plan added successfully');
            }
        }
    }
    
    if ($form_action === 'delete') {
        $id = intval($_POST['id'] ?? 0);
        // Check if any users have this plan
        $user_count = db_fetch_one("SELECT COUNT(*) as count FROM users WHERE plan_id = ?", 'i', [$id])['count'];
        if ($user_count > 0) {
            redirect('plans.php', 'error', "Cannot delete: $user_count user(s) have this plan");
        } else {
            db_query("DELETE FROM plans WHERE id = ?", 'i', [$id]);
            redirect('plans.php', 'success', 'Plan deleted successfully');
        }
    }
}

$edit_item = null;
if ($action === 'edit' && $edit_id) {
    $edit_item = db_fetch_one("SELECT * FROM plans WHERE id = ?", 'i', [$edit_id]);
    if (!$edit_item) redirect('plans.php', 'error', 'Plan not found');
}

$plans_list = db_fetch_all("SELECT p.*, (SELECT COUNT(*) FROM users WHERE plan_id = p.id) as user_count FROM plans p ORDER BY p.price");
?>

<?php if ($action === 'add' || $action === 'edit'): ?>
<div class="card">
    <div class="card-header">
        <i class="bi bi-<?= $action === 'edit' ? 'pencil' : 'plus-circle' ?> me-2"></i>
        <?= $action === 'edit' ? 'Edit Plan' : 'Add Plan' ?>
    </div>
    <div class="card-body">
        <form method="POST">
            <?= csrf_field() ?>
            <input type="hidden" name="form_action" value="save">
            <input type="hidden" name="id" value="<?= $edit_item['id'] ?? '' ?>">
            
            <div class="row">
                <div class="col-md-6">
                    <div class="mb-3">
                        <label class="form-label">Plan Name *</label>
                        <input type="text" name="name" class="form-control" required 
                               value="<?= e($edit_item['name'] ?? '') ?>" placeholder="e.g., Basic, Pro, Premium">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Price (₹)</label>
                        <input type="number" name="price" class="form-control" step="0.01" min="0"
                               value="<?= e($edit_item['price'] ?? '0') ?>">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Duration (Months)</label>
                        <select name="duration_months" class="form-select">
                            <?php foreach ([1, 3, 6, 12] as $m): ?>
                            <option value="<?= $m ?>" <?= ($edit_item['duration_months'] ?? 1) == $m ? 'selected' : '' ?>>
                                <?= $m ?> Month<?= $m > 1 ? 's' : '' ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                
                <div class="col-md-6">
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="3"><?= e($edit_item['description'] ?? '') ?></textarea>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Features (one per line)</label>
                        <textarea name="features" class="form-control" rows="4" placeholder="Market Updates&#10;Price Alerts&#10;Hindi News"><?php
                            if (isset($edit_item['features'])) {
                                $features = json_decode($edit_item['features'], true);
                                echo e(implode("\n", $features ?? []));
                            }
                        ?></textarea>
                    </div>
                    
                    <div class="form-check mb-3">
                        <input type="checkbox" name="is_active" class="form-check-input" id="is_active"
                               <?= ($edit_item['is_active'] ?? true) ? 'checked' : '' ?>>
                        <label class="form-check-label" for="is_active">Active (available for selection)</label>
                    </div>
                </div>
            </div>
            
            <hr>
            <div class="d-flex justify-content-between">
                <a href="plans.php" class="btn btn-secondary"><i class="bi bi-arrow-left me-2"></i>Cancel</a>
                <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-2"></i>Save Plan</button>
            </div>
        </form>
    </div>
</div>

<?php else: ?>
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="mb-0">Subscription Plans</h5>
    <a href="plans.php?action=add" class="btn btn-primary"><i class="bi bi-plus-circle me-2"></i>Add Plan</a>
</div>

<div class="row">
    <?php foreach ($plans_list as $plan): ?>
    <div class="col-md-4 mb-4">
        <div class="card h-100">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><?= e($plan['name']) ?></h5>
                <?= status_badge($plan['is_active'] ? 'active' : 'inactive') ?>
            </div>
            <div class="card-body">
                <h2 class="text-primary mb-3"><?= format_currency($plan['price']) ?>
                    <small class="text-muted fs-6">/ <?= $plan['duration_months'] ?> month<?= $plan['duration_months'] > 1 ? 's' : '' ?></small>
                </h2>
                
                <p class="text-muted"><?= e($plan['description']) ?></p>
                
                <?php
                $features = json_decode($plan['features'], true) ?? [];
                if (!empty($features)):
                ?>
                <ul class="list-unstyled">
                    <?php foreach ($features as $feature): ?>
                    <li><i class="bi bi-check-circle text-success me-2"></i><?= e($feature) ?></li>
                    <?php endforeach; ?>
                </ul>
                <?php endif; ?>
                
                <p class="mb-0">
                    <span class="badge bg-secondary"><?= $plan['user_count'] ?> users</span>
                </p>
            </div>
            <div class="card-footer bg-white border-0">
                <a href="plans.php?action=edit&id=<?= $plan['id'] ?>" class="btn btn-outline-primary btn-sm">
                    <i class="bi bi-pencil me-1"></i>Edit
                </a>
                <?php if ($plan['user_count'] == 0): ?>
                <form method="POST" class="d-inline" onsubmit="return confirmDelete('Delete this plan?')">
                    <?= csrf_field() ?>
                    <input type="hidden" name="form_action" value="delete">
                    <input type="hidden" name="id" value="<?= $plan['id'] ?>">
                    <button type="submit" class="btn btn-outline-danger btn-sm">
                        <i class="bi bi-trash me-1"></i>Delete
                    </button>
                </form>
                <?php endif; ?>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
    
    <?php if (empty($plans_list)): ?>
    <div class="col-12">
        <div class="empty-state card p-5">
            <i class="bi bi-credit-card"></i>
            <p>No plans created yet</p>
            <a href="plans.php?action=add" class="btn btn-primary">Add First Plan</a>
        </div>
    </div>
    <?php endif; ?>
</div>
<?php endif; ?>

<?php require_once 'includes/footer.php'; ?>
