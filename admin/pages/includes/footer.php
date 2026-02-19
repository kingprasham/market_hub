    </main>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <!-- jQuery (for DataTables) -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <!-- DataTables -->
    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>
    <!-- Custom JS -->
    <script>
        // Initialize DataTables
        $(document).ready(function() {
            $('.datatable').DataTable({
                responsive: true,
                pageLength: 10,
                order: [[0, 'desc']], // Order by first column descending
                language: {
                    search: "",
                    searchPlaceholder: "Search..."
                }
            });
        });
        
        // Confirm delete
        function confirmDelete(message) {
            return confirm(message || 'Are you sure you want to delete this item?');
        }
        
        // File preview
        function previewFile(input, previewId) {
            const preview = document.getElementById(previewId);
            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    if (input.files[0].type === 'application/pdf') {
                        preview.innerHTML = '<i class="bi bi-file-earmark-pdf text-danger" style="font-size: 48px;"></i><br><small>' + input.files[0].name + '</small>';
                    } else {
                        preview.innerHTML = '<img src="' + e.target.result + '" class="img-fluid rounded" style="max-height: 150px;">';
                    }
                }
                reader.readAsDataURL(input.files[0]);
            }
        }
    </script>
</body>
</html>
