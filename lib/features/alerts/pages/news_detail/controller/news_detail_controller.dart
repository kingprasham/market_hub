import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../data/models/content/news_model.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../core/storage/local_storage.dart';
import '../ui/news_detail_page.dart';
import '../binding/news_detail_binding.dart';

class NewsDetailController extends GetxController {
  final isLoading = true.obs;
  final isSaved = false.obs;
  late final NewsModel newsItem;
  final relatedNews = <NewsModel>[].obs;
  final hasValidNews = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Get the news item passed as argument
    if (Get.arguments != null && Get.arguments is NewsModel) {
      newsItem = Get.arguments as NewsModel;
      hasValidNews.value = true;
      // Check if already saved
      isSaved.value = LocalStorage.isNewsSaved(newsItem.id);
      _loadRelatedNews();
    } else {
      // Create a default placeholder news item
      newsItem = NewsModel(
        id: 'default',
        title: 'News Not Found',
        description: 'The requested news article could not be loaded.',
        newsType: 'english',
        targetPlanIds: ['basic'],
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      hasValidNews.value = false;
    }
    isLoading.value = false;
  }

  void _loadRelatedNews() {
    // Mock related news data
    relatedNews.assignAll([
      NewsModel(
        id: 'r1',
        title: 'LME Copper hits 6-month high on supply concerns',
        description: 'Copper prices surge amid tight supply and strong demand from China\'s manufacturing sector.',
        newsType: 'english',
        targetPlanIds: ['basic', 'premium'],
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        imageUrl: 'https://picsum.photos/400/250?random=1',
      ),
      NewsModel(
        id: 'r2',
        title: 'Gold steady as investors await Fed minutes',
        description: 'Gold prices remain stable as traders look for clues on future rate policy.',
        newsType: 'english',
        targetPlanIds: ['basic', 'premium'],
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        imageUrl: 'https://picsum.photos/400/250?random=2',
      ),
      NewsModel(
        id: 'r3',
        title: 'Zinc warehouse stocks drop to 2-year low',
        description: 'LME zinc inventories continue to decline amid strong demand from galvanizing sector.',
        newsType: 'english',
        targetPlanIds: ['basic', 'premium'],
        publishedAt: DateTime.now().subtract(const Duration(hours: 7)),
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        imageUrl: 'https://picsum.photos/400/250?random=3',
      ),
    ]);
  }

  void toggleSave() async {
    isSaved.value = !isSaved.value;
    
    if (isSaved.value) {
      // Save to local storage
      await LocalStorage.saveNews(newsItem.toJson());
    } else {
      // Remove from local storage
      await LocalStorage.unsaveNews(newsItem.id);
    }
    
    Get.snackbar(
      'Success',
      isSaved.value ? 'Article saved' : 'Article removed from saved',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void shareArticle() {
    final StringBuffer shareText = StringBuffer();
    shareText.writeln(newsItem.title);
    shareText.writeln();
    
    // Truncate description to 100 characters
    String description = newsItem.description;
    if (description.length > 100) {
      description = '${description.substring(0, 100)}...';
    }
    shareText.writeln(description);
    shareText.writeln();
    
    // Add App Link
    shareText.write('Read full story on Market Hub app:\nhttps://play.google.com/store/apps/details?id=com.markethub.app'); 
    
    Share.share(
      shareText.toString(),
      subject: newsItem.title,
    );
  }

  void openRelatedNews(NewsModel news) {
    Get.off(
      () => const NewsDetailPage(),
      arguments: news,
      binding: NewsDetailBinding(),
    );
  }

  void openPdf() {
    if (newsItem.hasPdf) {
      Get.toNamed(AppRoutes.pdfViewer, arguments: newsItem);
    }
  }
}
