import 'package:get/get.dart';
import '../../../../../data/models/content/news_model.dart';

class EventDetailController extends GetxController {
  final isLoading = true.obs;
  final isReminderSet = false.obs;
  late final NewsModel eventItem;

  // Mock economic event data - In real scenario, this would come from EconomicEventModel
  String get country => _extractCountry();
  String get countryCode => _extractCountryCode();
  String get impact => _extractImpact();
  String get previousValue => _extractPreviousValue();
  String get forecastValue => _extractForecastValue();
  String get actualValue => _extractActualValue();

  @override
  void onInit() {
    super.onInit();
    // Get the event item passed as argument
    if (Get.arguments != null && Get.arguments is NewsModel) {
      eventItem = Get.arguments as NewsModel;
    }
    isLoading.value = false;
  }

  String _extractCountry() {
    if (eventItem.title.contains('US') || eventItem.title.contains('Fed')) return 'United States';
    if (eventItem.title.contains('China')) return 'China';
    if (eventItem.title.contains('India') || eventItem.title.contains('RBI')) return 'India';
    if (eventItem.title.contains('ECB') || eventItem.title.contains('Euro')) return 'Eurozone';
    if (eventItem.title.contains('UK') || eventItem.title.contains('BOE')) return 'United Kingdom';
    if (eventItem.title.contains('Japan') || eventItem.title.contains('BOJ')) return 'Japan';
    return 'Global';
  }

  String _extractCountryCode() {
    if (country == 'United States') return 'US';
    if (country == 'China') return 'CN';
    if (country == 'India') return 'IN';
    if (country == 'Eurozone') return 'EU';
    if (country == 'United Kingdom') return 'GB';
    if (country == 'Japan') return 'JP';
    return 'GL';
  }

  String _extractImpact() {
    // Extract from title or description
    if (eventItem.title.contains('Non-Farm') ||
        eventItem.title.contains('CPI') ||
        eventItem.title.contains('Interest Rate')) {
      return 'high';
    } else if (eventItem.title.contains('PMI') ||
               eventItem.title.contains('Production')) {
      return 'medium';
    }
    return 'low';
  }

  String _extractPreviousValue() {
    final match = RegExp(r'Previous:\s*([^\|]+)').firstMatch(eventItem.description);
    return match?.group(1)?.trim() ?? 'N/A';
  }

  String _extractForecastValue() {
    final match = RegExp(r'Expected:\s*([^\|]+)').firstMatch(eventItem.description);
    return match?.group(1)?.trim() ?? 'N/A';
  }

  String _extractActualValue() {
    // Actual value would be populated after the event
    if (eventItem.publishedAt.isBefore(DateTime.now())) {
      return previousValue; // Show previous as actual for past events
    }
    return 'Pending';
  }

  void toggleReminder() {
    isReminderSet.value = !isReminderSet.value;
    Get.snackbar(
      'Success',
      isReminderSet.value
          ? 'Reminder set for this event'
          : 'Reminder removed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void addToCalendar() {
    Get.snackbar(
      'Coming Soon',
      'Calendar integration coming soon',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void shareEvent() {
    Get.snackbar(
      'Coming Soon',
      'Share functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
