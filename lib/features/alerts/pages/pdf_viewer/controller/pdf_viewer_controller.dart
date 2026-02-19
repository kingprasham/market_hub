import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../../data/models/content/news_model.dart';
import '../../../../../core/utils/helpers.dart';

class CircularPdfController extends GetxController {
  final isLoading = true.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  late final NewsModel pdfItem;
  late final Dio _dio;

  String? get pdfUrl => pdfItem.pdfUrl;

  @override
  void onInit() {
    super.onInit();

    // Initialize Dio with proper configuration
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': '*/*',
        'User-Agent': 'MarketHub/1.0',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    // Get the PDF item passed as argument
    if (Get.arguments != null && Get.arguments is NewsModel) {
      pdfItem = Get.arguments as NewsModel;
      debugPrint('PDF URL: ${pdfItem.pdfUrl}');
    }
    isLoading.value = false;
  }

  void onPageChanged(int page) {
    currentPage.value = page + 1;
  }

  void onDocumentLoaded(int pages) {
    totalPages.value = pages;
    isLoading.value = false;
    hasError.value = false;
  }

  void onDocumentError(dynamic error) {
    hasError.value = true;
    errorMessage.value = 'Failed to load PDF: $error';
    isLoading.value = false;
  }

  Future<void> downloadPdf() async {
    if (pdfUrl == null || pdfUrl!.isEmpty) {
      Helpers.showError('No PDF available to download');
      return;
    }

    try {
      isDownloading.value = true;
      downloadProgress.value = 0;

      // Get download directory
      final dir = await getApplicationDocumentsDirectory();
      // Sanitize filename to remove special characters
      final sanitizedTitle = pdfItem.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .substring(0, pdfItem.title.length > 50 ? 50 : pdfItem.title.length);
      final fileName = '$sanitizedTitle.pdf';
      final filePath = '${dir.path}/$fileName';

      debugPrint('Downloading PDF from: $pdfUrl');
      debugPrint('Saving to: $filePath');

      // Download file using configured Dio
      await _dio.download(
        pdfUrl!,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveDataWhenStatusError: true,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      isDownloading.value = false;
      Helpers.showSuccess('PDF downloaded successfully');

      // Open the downloaded file
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('OpenFilex error: ${result.message}');
      }
    } catch (e) {
      isDownloading.value = false;
      debugPrint('Download error: $e');
      Helpers.showError('Failed to download PDF. Please check your internet connection.');
    }
  }

  Future<void> sharePdf() async {
    if (pdfUrl == null || pdfUrl!.isEmpty) {
      Helpers.showError('No PDF available to share');
      return;
    }

    try {
      Helpers.showLoading(message: 'Preparing to share...');

      // Download to temp directory first
      final dir = await getTemporaryDirectory();
      final sanitizedTitle = pdfItem.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .substring(0, pdfItem.title.length > 50 ? 50 : pdfItem.title.length);
      final fileName = '$sanitizedTitle.pdf';
      final filePath = '${dir.path}/$fileName';

      await _dio.download(
        pdfUrl!,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      Helpers.hideLoading();

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: pdfItem.title,
      );
    } catch (e) {
      Helpers.hideLoading();
      debugPrint('Share PDF error: $e');
      // Fallback to sharing just the URL
      await Share.share(
        '${pdfItem.title}\n\n$pdfUrl',
        subject: pdfItem.title,
      );
    }
  }

  String get pdfMetadata {
    return 'Document: ${pdfItem.title}\n'
        'Pages: $totalPages\n'
        'Format: PDF\n'
        'Published: ${pdfItem.publishedAt.toString().split(' ')[0]}';
  }
}
