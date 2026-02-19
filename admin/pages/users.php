<?php
/**
 * Market Hub Admin - Users List
 */
$page_title = 'User Management';
require_once 'includes/header.php';

// Handle quick actions
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if (!verify_csrf($_POST['csrf_token'] ?? '')) {
        redirect('users.php', 'error', 'Invalid request');
    }
    
    $user_id = intval($_POST['user_id'] ?? 0);
    
    if ($_POST['action'] === 'approve') {
        $plan_id = intval($_POST['plan_id'] ?? 0);
        $duration = intval($_POST['duration'] ?? 1);
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
        
        redirect('users.php', 'success', 'User approved successfully');
    }
    
    if ($_POST['action'] === 'reject') {
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
        
        redirect('users.php', 'success', 'User rejected');
    }
}

// Get filter
$status_filter = $_GET['status'] ?? 'all';
$where = '';
if (in_array($status_filter, ['pending', 'approved', 'rejected'])) {
    $where = "WHERE status = '$status_filter'";
}

// Get users
$users = db_fetch_all("SELECT u.*, p.name as plan_name FROM users u LEFT JOIN plans p ON u.plan_id = p.id $where ORDER BY u.created_at DESC");
$plans = db_fetch_all("SELECT * FROM plans WHERE is_active = 1 ORDER BY price");
?>

<!-- Filter Tabs -->
<ul class="nav nav-tabs mb-4">
    <li class="nav-item">
        <a class="nav-link <?= $status_filter === 'all' ? 'active' : '' ?>" href="users.php">
            All Users
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link <?= $status_filter === 'pending' ? 'active' : '' ?>" href="users.php?status=pending">
            <i class="bi bi-hourglass-split text-warning"></i> Pending
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link <?= $status_filter === 'approved' ? 'active' : '' ?>" href="users.php?status=approved">
            <i class="bi bi-check-circle text-success"></i> Approved
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link <?= $status_filter === 'rejected' ? 'active' : '' ?>" href="users.php?status=rejected">
            <i class="bi bi-x-circle text-danger"></i> Rejected
        </a>
    </li>
</ul>

<div class="card">
    <div class="card-body">
        <?php if (empty($users)): ?>
        <div class="empty-state">
            <i class="bi bi-inbox"></i>
            <p>No users found</p>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table datatable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Plan</th>
                        <th>Status</th>
                        <th>Registered</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($users as $user): ?>
                    <tr>
                        <td><?= $user['id'] ?></td>
                        <td>
                            <strong><?= e($user['full_name']) ?></strong>
                            <?php if ($user['visiting_card']): ?>
                            <br><small class="text-muted"><i class="bi bi-image"></i> Card uploaded</small>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?= e($user['email']) ?>
                            <?php if ($user['email_verified']): ?>
                            <i class="bi bi-patch-check-fill text-success" title="Verified"></i>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?= e($user['phone']) ?>
                            <?php if ($user['whatsapp']): ?>
                            <br><small class="text-success"><i class="bi bi-whatsapp"></i> <?= e($user['whatsapp']) ?></small>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?= e($user['plan_name'] ?? '-') ?>
                            <?php if ($user['plan_expires_at']): ?>
                            <br><small class="text-muted">Expires: <?= format_date($user['plan_expires_at'], 'd M Y') ?></small>
                            <?php endif; ?>
                        </td>
                        <td><?= status_badge($user['status']) ?></td>
                        <td><?= format_date($user['created_at'], 'd M Y') ?></td>
                        <td class="action-btns">
                            <a href="user_view.php?id=<?= $user['id'] ?>" class="btn btn-sm btn-outline-primary" title="View">
                                <i class="bi bi-eye"></i>
                            </a>
                            
                            <?php if ($user['status'] === 'pending'): ?>
                            <button class="btn btn-sm btn-success" data-bs-toggle="modal" data-bs-target="#approveModal<?= $user['id'] ?>" title="Approve">
                                <i class="bi bi-check-lg"></i>
                            </button>
                            <button class="btn btn-sm btn-danger" data-bs-toggle="modal" data-bs-target="#rejectModal<?= $user['id'] ?>" title="Reject">
                                <i class="bi bi-x-lg"></i>
                            </button>
                            <?php endif; ?>
                        </td>
                    </tr>
                    
                    <?php if ($user['status'] === 'pending'): ?>
                    <!-- Approve Modal -->
                    <div class="modal fade" id="approveModal<?= $user['id'] ?>" tabindex="-1">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title"><i class="bi bi-check-circle me-2"></i>Approve User</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <form method="POST">
                                    <div class="modal-body">
                                        <?= csrf_field() ?>
                                        <input type="hidden" name="action" value="approve">
                                        <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                                        
                                        <p>Approve <strong><?= e($user['full_name']) ?></strong>?</p>
                                        
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
                                            <label class="form-label">Duration (months)</label>
                                            <select name="duration" class="form-select">
                                                <option value="1">1 Month</option>
                                                <option value="3">3 Months</option>
                                                <option value="6">6 Months</option>
                                                <option value="12" selected>12 Months</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                        <button type="submit" class="btn btn-success"><i class="bi bi-check-lg me-2"></i>Approve</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Reject Modal -->
                    <div class="modal fade" id="rejectModal<?= $user['id'] ?>" tabindex="-1">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title"><i class="bi bi-x-circle me-2"></i>Reject User</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <form method="POST">
                                    <div class="modal-body">
                                        <?= csrf_field() ?>
                                        <input type="hidden" name="action" value="reject">
                                        <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                                        
                                        <p>Reject <strong><?= e($user['full_name']) ?></strong>?</p>
                                        
                                        <div class="mb-3">
                                            <label class="form-label">Reason for rejection</label>
                                            <textarea name="reason" class="form-control" rows="3" placeholder="Optional: Provide reason for rejection"></textarea>
                                        </div>
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                        <button type="submit" class="btn btn-danger"><i class="bi bi-x-lg me-2"></i>Reject</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                    <?php endif; ?>
                    
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
