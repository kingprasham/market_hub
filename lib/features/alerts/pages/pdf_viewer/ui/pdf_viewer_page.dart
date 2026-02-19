import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/pdf_viewer_controller.dart';

class PdfViewerPage extends GetView<CircularPdfController> {
  const PdfViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.pdfItem.title,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorConstants.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              Formatters.formatDate(controller.pdfItem.publishedAt),
              style: TextStyles.caption.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Download button with progress
          Obx(() => controller.isDownloading.value
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: controller.downloadProgress.value,
                      strokeWidth: 2,
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: controller.downloadPdf,
                  icon: const Icon(Icons.download_outlined, color: ColorConstants.textPrimary),
                )),
          IconButton(
            onPressed: controller.sharePdf,
            icon: const Icon(Icons.share_outlined, color: ColorConstants.textPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: ShimmerListLoader());
        }

        // Check if PDF URL is available
        if (controller.pdfUrl == null || controller.pdfUrl!.isEmpty) {
          return _buildNoPdfView();
        }

        // Check for error
        if (controller.hasError.value) {
          return _buildErrorView();
        }

        return Column(
          children: [
            // Page indicator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Obx(() => Text(
                'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              )),
            ),

            // PDF Viewer
            Expanded(
              child: SfPdfViewer.network(
                controller.pdfUrl!,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                enableDoubleTapZooming: true,
                onDocumentLoaded: (details) {
                  controller.onDocumentLoaded(details.document.pages.count);
                },
                onPageChanged: (details) {
                  controller.onPageChanged(details.newPageNumber - 1);
                },
                onDocumentLoadFailed: (details) {
                  debugPrint('PDF load failed: ${details.description}');
                  debugPrint('PDF URL was: ${controller.pdfUrl}');
                  controller.onDocumentError(details.description);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNoPdfView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 80,
            color: Colors.red.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No PDF Available',
            style: TextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'This document does not have a PDF attached.',
              style: TextStyles.bodyMedium.copyWith(
                color: ColorConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Show document info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Info',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.pdfItem.title,
                  style: TextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.pdfItem.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: ColorConstants.errorColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load PDF',
              style: TextStyles.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Unable to display PDF in the app. You can download it to view externally.',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    controller.hasError.value = false;
                    controller.isLoading.value = true;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      controller.isLoading.value = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => controller.isDownloading.value
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: controller.downloadProgress.value,
                                strokeWidth: 2,
                                color: ColorConstants.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(controller.downloadProgress.value * 100).toInt()}%'),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: controller.downloadPdf,
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      )),
              ],
            ),
            const SizedBox(height: 32),
            // Show document info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorConstants.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Info',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.pdfItem.title,
                    style: TextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.pdfItem.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
