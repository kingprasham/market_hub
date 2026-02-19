import 'package:get/get.dart';
import '../controller/news_detail_controller.dart';

class NewsDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewsDetailController>(() => NewsDetailController());
  }
}
