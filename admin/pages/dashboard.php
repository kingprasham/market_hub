<?php
/**
 * Market Hub Admin - Dashboard
 */
$page_title = 'Dashboard';
require_once 'includes/header.php';

// Get stats
$total_users = db_fetch_one("SELECT COUNT(*) as count FROM users")['count'] ?? 0;
$pending_users = db_fetch_one("SELECT COUNT(*) as count FROM users WHERE status = 'pending'")['count'] ?? 0;
$approved_users = db_fetch_one("SELECT COUNT(*) as count FROM users WHERE status = 'approved'")['count'] ?? 0;
$total_news = db_fetch_one("SELECT COUNT(*) as count FROM news WHERE is_active = 1")['count'] ?? 0;
$total_circulars = db_fetch_one("SELECT COUNT(*) as count FROM circulars WHERE is_active = 1")['count'] ?? 0;
$total_updates = db_fetch_one("SELECT COUNT(*) as count FROM home_updates WHERE is_active = 1")['count'] ?? 0;
$unread_feedback = db_fetch_one("SELECT COUNT(*) as count FROM feedback WHERE is_read = 0")['count'] ?? 0;

// Recent registrations (last 7 days)
$recent_users = db_fetch_all(
    "SELECT * FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) ORDER BY created_at DESC LIMIT 5"
);
?>

<!-- Stats Row -->
<div class="row mb-4">
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon orange">
                <i class="bi bi-people"></i>
            </div>
            <div class="stat-value"><?= $total_users ?></div>
            <div class="stat-label">Total Users</div>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon yellow">
                <i class="bi bi-hourglass-split"></i>
            </div>
            <div class="stat-value"><?= $pending_users ?></div>
            <div class="stat-label">Pending Approvals</div>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon green">
                <i class="bi bi-check-circle"></i>
            </div>
            <div class="stat-value"><?= $approved_users ?></div>
            <div class="stat-label">Approved Users</div>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon blue">
                <i class="bi bi-newspaper"></i>
            </div>
            <div class="stat-value"><?= $total_news ?></div>
            <div class="stat-label">Active News</div>
        </div>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon orange">
                <i class="bi bi-file-earmark-pdf"></i>
            </div>
            <div class="stat-value"><?= $total_circulars ?></div>
            <div class="stat-label">Circulars</div>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon blue">
                <i class="bi bi-megaphone"></i>
            </div>
            <div class="stat-value"><?= $total_updates ?></div>
            <div class="stat-label">Home Updates</div>
        </div>
    </div>
    <div class="col-md-3 mb-3">
        <div class="stat-card">
            <div class="stat-icon green">
                <i class="bi bi-chat-dots"></i>
            </div>
            <div class="stat-value"><?= $unread_feedback ?></div>
            <div class="stat-label">Unread Feedback</div>
        </div>
    </div>
</div>

<div class="row">
    <!-- Recent Registrations -->
    <div class="col-lg-8 mb-4">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="bi bi-clock-history me-2"></i>Recent Registrations</span>
                <a href="users.php" class="btn btn-sm btn-outline-primary">View All</a>
            </div>
            <div class="card-body">
                <?php if (empty($recent_users)): ?>
                <div class="empty-state py-4">
                    <i class="bi bi-inbox"></i>
                    <p>No recent registrations</p>
                </div>
                <?php else: ?>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Registered</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($recent_users as $user): ?>
                            <tr>
                                <td><strong><?= e($user['full_name']) ?></strong></td>
                                <td><?= e($user['email']) ?></td>
                                <td><?= status_badge($user['status']) ?></td>
                                <td><?= format_date($user['created_at'], 'd M, h:i A') ?></td>
                                <td>
                                    <a href="user_view.php?id=<?= $user['id'] ?>" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <!-- Quick Actions -->
    <div class="col-lg-4 mb-4">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-lightning me-2"></i>Quick Actions
            </div>
            <div class="card-body">
                <div class="d-grid gap-2">
                    <a href="users.php?status=pending" class="btn btn-warning">
                        <i class="bi bi-person-check me-2"></i>Review Pending Users
                        <?php if ($pending_users > 0): ?>
                        <span class="badge bg-dark ms-2"><?= $pending_users ?></span>
                        <?php endif; ?>
                    </a>
                    <a href="home_updates.php?action=add" class="btn btn-primary">
                        <i class="bi bi-plus-circle me-2"></i>Add Home Update
                    </a>
                    <a href="news.php?action=add" class="btn btn-outline-primary">
                        <i class="bi bi-newspaper me-2"></i>Add News
                    </a>
                    <a href="circulars.php?action=add" class="btn btn-outline-primary">
                        <i class="bi bi-file-earmark-pdf me-2"></i>Add Circular
                    </a>
                    <a href="feedback.php" class="btn btn-outline-secondary">
                        <i class="bi bi-chat-dots me-2"></i>View Feedback
                        <?php if ($unread_feedback > 0): ?>
                        <span class="badge bg-success ms-2"><?= $unread_feedback ?></span>
                        <?php endif; ?>
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
