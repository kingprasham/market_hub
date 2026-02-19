<?php
/**
 * Market Hub Admin - View User Details
 */
$page_title = 'User Details';

$user_id = intval($_GET['id'] ?? 0);
if (!$user_id) {
    header('Location: users.php');
    exit;
}

require_once 'includes/header.php';

// Get user with plan info
$user = db_fetch_one(
    "SELECT u.*, p.name as plan_name, p.price as plan_price, p.duration_months 
     FROM users u 
     LEFT JOIN plans p ON u.plan_id = p.id 
     WHERE u.id = ?",
    'i',
    [$user_id]
);

if (!$user) {
    redirect('users.php', 'error', 'User not found');
}

$plans = db_fetch_all("SELECT * FROM plans WHERE is_active = 1 ORDER BY price");

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect("user_view.php?id=$user_id", 'error', 'Invalid request');
    }
    
    $action = $_POST['action'] ?? '';
    
    if ($action === 'update_plan') {
        $plan_id = intval($_POST['plan_id'] ?? 0);
        $expires_at = $_POST['expires_at'] ?? null;
        
        db_query(
            "UPDATE users SET plan_id = ?, plan_expires_at = ? WHERE id = ?",
            'isi',
            [$plan_id ?: null, $expires_at ?: null, $user_id]
        );
        
        redirect("user_view.php?id=$user_id", 'success', 'Plan updated successfully');
    }
    
    if ($action === 'approve') {
        $plan_id = intval($_POST['plan_id'] ?? 0);
        $duration = intval($_POST['duration'] ?? 12);
        $expires_at = date('Y-m-d H:i:s', strtotime("+$duration months"));
        
        db_query(
            "UPDATE users SET status = 'approved', approved_at = NOW(), plan_id = ?, plan_expires_at = ? WHERE id = ?",
            'isi',
            [$plan_id, $expires_at, $user_id]
        );
        
        // Send push notification to user
        send_user_notification(
            $user_id,
            'Account Approved ✅', 
            'Your Market Hub account has been approved! You can now access premium features.',
            ['type' => 'account_status', 'status' => 'approved']
        );
        
        redirect("user_view.php?id=$user_id", 'success', 'User approved successfully');
    }
    
    if ($action === 'reject') {
        $reason = trim($_POST['reason'] ?? '');
        db_query(
            "UPDATE users SET status = 'rejected', rejection_reason = ? WHERE id = ?",
            'si',
            [$reason, $user_id]
        );
        
        // Send push notification to user
        send_user_notification(
            $user_id,
            'Account Application Update ⚠️',
            'Your account application was not approved: ' . ($reason ?: 'Criteria not met'),
            ['type' => 'account_status', 'status' => 'rejected']
        );
        
        redirect("user_view.php?id=$user_id", 'success', 'User rejected');
    }
}
?>

<div class="mb-3">
    <a href="users.php" class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left me-2"></i>Back to Users
    </a>
</div>

<div class="row">
    <!-- User Info -->
    <div class="col-lg-8">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="bi bi-person me-2"></i>User Information</span>
                <?= status_badge($user['status']) ?>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Full Name</label>
                        <p class="mb-0 fw-bold"><?= e($user['full_name']) ?></p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Email</label>
                        <p class="mb-0">
                            <?= e($user['email']) ?>
                            <?php if ($user['email_verified']): ?>
                            <span class="badge bg-success ms-2"><i class="bi bi-check"></i> Verified</span>
                            <?php else: ?>
                            <span class="badge bg-warning text-dark ms-2">Not Verified</span>
                            <?php endif; ?>
                        </p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Phone</label>
                        <p class="mb-0"><?= e($user['phone']) ?: '-' ?></p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">WhatsApp</label>
                        <p class="mb-0">
                            <?php if ($user['whatsapp']): ?>
                            <a href="https://wa.me/<?= preg_replace('/[^0-9]/', '', $user['whatsapp']) ?>" target="_blank" class="text-success">
                                <i class="bi bi-whatsapp me-1"></i><?= e($user['whatsapp']) ?>
                            </a>
                            <?php else: ?>
                            -
                            <?php endif; ?>
                        </p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">PIN Code</label>
                        <p class="mb-0"><?= e($user['pin_code']) ?: '-' ?></p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Registered On</label>
                        <p class="mb-0"><?= format_date($user['created_at']) ?></p>
                    </div>
                    
                    <?php if ($user['status'] === 'approved'): ?>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Approved On</label>
                        <p class="mb-0"><?= format_date($user['approved_at']) ?></p>
                    </div>
                    <?php endif; ?>
                    
                    <?php if ($user['status'] === 'rejected' && $user['rejection_reason']): ?>
                    <div class="col-12 mb-3">
                        <label class="text-muted small">Rejection Reason</label>
                        <p class="mb-0 text-danger"><?= e($user['rejection_reason']) ?></p>
                    </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Plan Info -->
        <div class="card mb-4">
            <div class="card-header">
                <i class="bi bi-credit-card me-2"></i>Subscription Plan
            </div>
            <div class="card-body">
                <?php if ($user['plan_id']): ?>
                <div class="row">
                    <div class="col-md-4 mb-3">
                        <label class="text-muted small">Plan Name</label>
                        <p class="mb-0 fw-bold"><?= e($user['plan_name']) ?></p>
                    </div>
                    <div class="col-md-4 mb-3">
                        <label class="text-muted small">Price</label>
                        <p class="mb-0"><?= format_currency($user['plan_price']) ?></p>
                    </div>
                    <div class="col-md-4 mb-3">
                        <label class="text-muted small">Expires On</label>
                        <p class="mb-0">
                            <?php
                            if ($user['plan_expires_at']) {
                                $expires = strtotime($user['plan_expires_at']);
                                $now = time();
                                if ($expires < $now) {
                                    echo '<span class="text-danger">' . format_date($user['plan_expires_at'], 'd M Y') . ' (Expired)</span>';
                                } else {
                                    echo format_date($user['plan_expires_at'], 'd M Y');
                                }
                            } else {
                                echo '-';
                            }
                            ?>
                        </p>
                    </div>
                </div>
                <?php else: ?>
                <p class="text-muted mb-0">No plan assigned</p>
                <?php endif; ?>
                
                <?php if ($user['status'] === 'approved'): ?>
                <hr>
                <form method="POST" class="row g-3">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="update_plan">
                    
                    <div class="col-md-5">
                        <label class="form-label">Change Plan</label>
                        <select name="plan_id" class="form-select">
                            <option value="">Select Plan</option>
                            <?php foreach ($plans as $plan): ?>
                            <option value="<?= $plan['id'] ?>" <?= $user['plan_id'] == $plan['id'] ? 'selected' : '' ?>>
                                <?= e($plan['name']) ?> - <?= format_currency($plan['price']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Expiry Date</label>
                        <input type="date" name="expires_at" class="form-control" 
                               value="<?= $user['plan_expires_at'] ? date('Y-m-d', strtotime($user['plan_expires_at'])) : '' ?>">
                    </div>
                    <div class="col-md-3 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100">Update Plan</button>
                    </div>
                </form>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <!-- Sidebar -->
    <div class="col-lg-4">
        <!-- Visiting Card -->
        <div class="card mb-4">
            <div class="card-header">
                <i class="bi bi-image me-2"></i>Visiting Card
            </div>
            <div class="card-body text-center">
                <?php if ($user['visiting_card'] && file_exists_upload($user['visiting_card'])): ?>
                <a href="<?= file_url($user['visiting_card']) ?>" target="_blank">
                    <img src="<?= file_url($user['visiting_card']) ?>" class="img-fluid rounded" style="max-height: 300px;">
                </a>
                <p class="text-muted small mt-2">Click to view full size</p>
                <?php else: ?>
                <div class="empty-state py-4">
                    <i class="bi bi-image" style="font-size: 48px; opacity: 0.3;"></i>
                    <p class="text-muted">No visiting card uploaded</p>
                </div>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Actions -->
        <?php if ($user['status'] === 'pending'): ?>
        <div class="card mb-4">
            <div class="card-header">
                <i class="bi bi-lightning me-2"></i>Actions
            </div>
            <div class="card-body">
                <form method="POST" class="mb-3">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="approve">
                    
                    <div class="mb-3">
                        <label class="form-label">Assign Plan *</label>
                        <select name="plan_id" class="form-select" required>
                            <option value="">Select Plan</option>
                            <?php foreach ($plans as $plan): ?>
                            <option value="<?= $plan['id'] ?>"><?= e($plan['name']) ?> - <?= format_currency($plan['price']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Duration</label>
                        <select name="duration" class="form-select">
                            <option value="1">1 Month</option>
                            <option value="3">3 Months</option>
                            <option value="6">6 Months</option>
                            <option value="12" selected>12 Months</option>
                        </select>
                    </div>
                    
                    <button type="submit" class="btn btn-success w-100">
                        <i class="bi bi-check-lg me-2"></i>Approve User
                    </button>
                </form>
                
                <hr>
                
                <form method="POST">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="reject">
                    
                    <div class="mb-3">
                        <label class="form-label">Rejection Reason</label>
                        <textarea name="reason" class="form-control" rows="2" placeholder="Optional"></textarea>
                    </div>
                    
                    <button type="submit" class="btn btn-outline-danger w-100" onclick="return confirm('Are you sure you want to reject this user?')">
                        <i class="bi bi-x-lg me-2"></i>Reject User
                    </button>
                </form>
            </div>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
