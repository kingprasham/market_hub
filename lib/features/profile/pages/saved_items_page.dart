import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/content/news_model.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> {
  List<Map<String, dynamic>> savedNews = [];

  @override
  void initState() {
    super.initState();
    _loadSavedNews();
  }

  void _loadSavedNews() {
    setState(() {
      savedNews = LocalStorage.getSavedNews();
    });
  }

  Future<void> _unsaveNews(String newsId) async {
    await LocalStorage.unsaveNews(newsId);
    _loadSavedNews();
    Get.snackbar(
      'Removed',
      'Article removed from saved items',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _openNewsDetail(Map<String, dynamic> newsJson) {
    final news = NewsModel.fromJson(newsJson);
    Get.toNamed(AppRoutes.newsDetail, arguments: news);
  }

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
        title: Text(
          'Saved Items',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: savedNews.isEmpty ? _buildEmptyState() : _buildNewsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ColorConstants.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 48,
              color: ColorConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Items',
            style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Save news articles to read them later',
            style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.explore),
            label: const Text('Browse News'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: () async => _loadSavedNews(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: savedNews.length,
        itemBuilder: (context, index) {
          final newsJson = savedNews[index];
          return _buildSavedNewsCard(newsJson);
        },
      ),
    );
  }

  Widget _buildSavedNewsCard(Map<String, dynamic> newsJson) {
    final title = newsJson['title'] ?? 'Untitled';
    final publishedAtStr = newsJson['publishedAt'];
    DateTime publishedAt = DateTime.now();
    if (publishedAtStr != null) {
      publishedAt = DateTime.tryParse(publishedAtStr) ?? DateTime.now();
    }
    final imageUrl = newsJson['imageUrl'];
    final newsId = newsJson['id'] ?? '';

    return Dismissible(
      key: Key(newsId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ColorConstants.negativeRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => _unsaveNews(newsId),
      child: GestureDetector(
        onTap: () => _openNewsDetail(newsJson),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Icon(
                        Icons.article,
                        color: ColorConstants.primaryOrange,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatRelativeTime(publishedAt),
                      style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                    ),
                  ],
                ),
              ),
              // Unsave button
              IconButton(
                onPressed: () => _unsaveNews(newsId),
                icon: const Icon(
                  Icons.bookmark,
                  color: ColorConstants.primaryOrange,
                ),
                tooltip: 'Remove from saved',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
