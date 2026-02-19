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

        // Generic Upload with Progress
        async function uploadWithProgress(form, progressBarId, submitBtn) {
            const formData = new FormData(form);
            const progressBar = document.getElementById(progressBarId);
            const bar = progressBar.querySelector('.progress-bar');
            
            // Show progress bar
            progressBar.classList.remove('d-none');
            bar.style.width = '0%';
            bar.innerText = '0%';
            if(submitBtn) submitBtn.disabled = true;

            try {
                // Compress images if present
                for (let [key, value] of formData.entries()) {
                    if (value instanceof File && value.type.startsWith('image/')) {
                        console.log('Compressing ' + value.name + ' (' + (value.size/1024).toFixed(2) + ' KB)');
                        try {
                            const compressedFile = await new Promise((resolve, reject) => {
                                new Compressor(value, {
                                    quality: 0.6,
                                    maxWidth: 1920,
                                    maxHeight: 1920,
                                    success(result) {
                                        console.log('Compressed to ' + (result.size/1024).toFixed(2) + ' KB');
                                        resolve(result);
                                    },
                                    error(err) {
                                        console.warn('Compression failed, using original', err);
                                        resolve(value);
                                    },
                                });
                            });
                            formData.set(key, compressedFile, value.name);
                        } catch (e) {
                            console.warn('Compression skipped', e);
                        }
                    }
                }

                // Upload
                const xhr = new XMLHttpRequest();
                xhr.open('POST', form.action || window.location.href, true);
                
                // Track progress
                xhr.upload.onprogress = function(e) {
                    if (e.lengthComputable) {
                        const percent = Math.round((e.loaded / e.total) * 100);
                        bar.style.width = percent + '%';
                        bar.innerText = percent + '%';
                    }
                };

                xhr.onload = function() {
                    if (xhr.status === 200) {
                        // Assuming the PHP script redirects on success or returns HTML
                        // If it redirects, the browser follows. If we want to stay and show message:
                        // But existing PHP redirects. AJAX following redirect is tricky.
                        // Instead, we check the response URL.
                        if (xhr.responseURL !== window.location.href) {
                             window.location.href = xhr.responseURL;
                        } else {
                             // Reload or show message
                             window.location.reload();
                        }
                    } else {
                        alert('Upload failed with status ' + xhr.status);
                        if(submitBtn) submitBtn.disabled = false;
                    }
                };
                
                xhr.onerror = function() {
                    alert('Upload failed due to network error');
                    if(submitBtn) submitBtn.disabled = false;
                };

                xhr.send(formData);

            } catch (error) {
                console.error(error);
                alert('An error occurred during upload processing');
                if(submitBtn) submitBtn.disabled = false;
            }
            
            return false; // Prevent default form submit
        }
    </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/compressorjs/1.2.1/compressor.min.js"></script>
</body>
</html>
