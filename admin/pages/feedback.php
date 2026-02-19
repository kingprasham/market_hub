<?php
/**
 * Market Hub Admin - Feedback Management
 */
$page_title = 'User Feedback';
require_once 'includes/header.php';

// Handle mark as read
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['mark_read'])) {
    if (verify_csrf($_POST['csrf_token'] ?? '')) {
        $id = intval($_POST['id'] ?? 0);
        db_query("UPDATE feedback SET is_read = 1 WHERE id = ?", 'i', [$id]);
        redirect('feedback.php', 'success', 'Marked as read');
    }
}

// Get all feedback with user info
$feedback_list = db_fetch_all(
    "SELECT f.*, u.full_name, u.email 
     FROM feedback f 
     LEFT JOIN users u ON f.user_id = u.id 
     ORDER BY f.created_at DESC"
);

$unread_count = db_fetch_one("SELECT COUNT(*) as count FROM feedback WHERE is_read = 0")['count'] ?? 0;
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="mb-0">
        User Feedback
        <?php if ($unread_count > 0): ?>
        <span class="badge bg-warning text-dark ms-2"><?= $unread_count ?> unread</span>
        <?php endif; ?>
    </h5>
</div>

<div class="card">
    <div class="card-body">
        <?php if (empty($feedback_list)): ?>
        <div class="empty-state">
            <i class="bi bi-chat-dots"></i>
            <p>No feedback received yet</p>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table datatable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>User</th>
                        <th>Rating</th>
                        <th>Message</th>
                        <th>Date</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($feedback_list as $item): ?>
                    <tr class="<?= $item['is_read'] ? '' : 'table-warning' ?>">
                        <td><?= $item['id'] ?></td>
                        <td>
                            <?php if ($item['full_name']): ?>
                            <strong><?= e($item['full_name']) ?></strong>
                            <br><small class="text-muted"><?= e($item['email']) ?></small>
                            <?php else: ?>
                            <span class="text-muted">Anonymous</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if ($item['rating']): ?>
                            <?php for ($i = 1; $i <= 5; $i++): ?>
                            <i class="bi bi-star<?= $i <= $item['rating'] ? '-fill text-warning' : '' ?>"></i>
                            <?php endfor; ?>
                            <?php else: ?>
                            -
                            <?php endif; ?>
                        </td>
                        <td><?= e(truncate($item['message'], 100)) ?></td>
                        <td><?= format_date($item['created_at'], 'd M Y, h:i A') ?></td>
                        <td>
                            <?php if ($item['is_read']): ?>
                            <span class="badge bg-secondary">Read</span>
                            <?php else: ?>
                            <span class="badge bg-warning text-dark">Unread</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if (!$item['is_read']): ?>
                            <form method="POST" class="d-inline">
                                <?= csrf_field() ?>
                                <input type="hidden" name="mark_read" value="1">
                                <input type="hidden" name="id" value="<?= $item['id'] ?>">
                                <button type="submit" class="btn btn-sm btn-outline-success" title="Mark as Read">
                                    <i class="bi bi-check-lg"></i>
                                </button>
                            </form>
                            <?php endif; ?>
                            <button class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#viewModal<?= $item['id'] ?>">
                                <i class="bi bi-eye"></i>
                            </button>
                        </td>
                    </tr>
                    
                    <!-- View Modal -->
                    <div class="modal fade" id="viewModal<?= $item['id'] ?>" tabindex="-1">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">Feedback Details</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <p><strong>From:</strong> <?= e($item['full_name'] ?? 'Anonymous') ?></p>
                                    <?php if ($item['email']): ?>
                                    <p><strong>Email:</strong> <?= e($item['email']) ?></p>
                                    <?php endif; ?>
                                    <?php if ($item['rating']): ?>
                                    <p><strong>Rating:</strong> 
                                        <?php for ($i = 1; $i <= 5; $i++): ?>
                                        <i class="bi bi-star<?= $i <= $item['rating'] ? '-fill text-warning' : '' ?>"></i>
                                        <?php endfor; ?>
                                    </p>
                                    <?php endif; ?>
                                    <p><strong>Date:</strong> <?= format_date($item['created_at']) ?></p>
                                    <hr>
                                    <p><strong>Message:</strong></p>
                                    <div class="bg-light p-3 rounded"><?= nl2br(e($item['message'])) ?></div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
