import 'package:get/get.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/helpers.dart';

class SettingsController extends GetxController {
  // Notification settings
  final notificationsEnabled = true.obs;
  final priceAlertsEnabled = true.obs;
  final newsAlertsEnabled = true.obs;

  // Security settings
  final biometricEnabled = false.obs;

  // Preference settings
  final darkModeEnabled = false.obs;
  final selectedLanguage = 'English'.obs;
  final selectedCurrency = 'INR (₹)'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    // Load settings from local storage
    final settings = LocalStorage.getCachedData('app_settings');
    if (settings != null) {
      notificationsEnabled.value = settings['notifications_enabled'] ?? true;
      priceAlertsEnabled.value = settings['price_alerts_enabled'] ?? true;
      newsAlertsEnabled.value = settings['news_alerts_enabled'] ?? true;
      biometricEnabled.value = settings['biometric_enabled'] ?? false;
      darkModeEnabled.value = settings['dark_mode_enabled'] ?? false;
      selectedLanguage.value = settings['language'] ?? 'English';
      selectedCurrency.value = settings['currency'] ?? 'INR (₹)';
    }
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    if (!value) {
      priceAlertsEnabled.value = false;
      newsAlertsEnabled.value = false;
    }
    await _saveSettings();
  }

  Future<void> togglePriceAlerts(bool value) async {
    if (notificationsEnabled.value) {
      priceAlertsEnabled.value = value;
      await _saveSettings();
    }
  }

  Future<void> toggleNewsAlerts(bool value) async {
    if (notificationsEnabled.value) {
      newsAlertsEnabled.value = value;
      await _saveSettings();
    }
  }

  Future<void> toggleBiometric(bool value) async {
    biometricEnabled.value = value;
    await _saveSettings();

    if (value) {
      Helpers.showSuccess('Biometric authentication enabled');
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    darkModeEnabled.value = value;
    await _saveSettings();
    Helpers.showSnackBar(message: 'Theme will be applied on restart');
  }

  Future<void> _saveSettings() async {
    final settings = {
      'notifications_enabled': notificationsEnabled.value,
      'price_alerts_enabled': priceAlertsEnabled.value,
      'news_alerts_enabled': newsAlertsEnabled.value,
      'biometric_enabled': biometricEnabled.value,
      'dark_mode_enabled': darkModeEnabled.value,
      'language': selectedLanguage.value,
      'currency': selectedCurrency.value,
    };
    await LocalStorage.cacheData('app_settings', settings);
  }
}
