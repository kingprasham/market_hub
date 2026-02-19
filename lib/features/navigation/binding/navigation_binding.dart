import 'package:get/get.dart';
import '../controller/navigation_controller.dart';
import '../../home/controller/home_controller.dart';
import '../../future/controller/future_controller.dart';
import '../../spot_price/controller/spot_price_controller.dart';
import '../../alerts/controller/alerts_controller.dart';
import '../../watchlist/controller/watchlist_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NavigationController>(NavigationController());
    Get.put<HomeController>(HomeController());
    Get.put<FutureController>(FutureController());
    Get.put<SpotPriceController>(SpotPriceController());
    Get.put<AlertsController>(AlertsController());
    Get.put<WatchlistController>(WatchlistController());
  }
}
