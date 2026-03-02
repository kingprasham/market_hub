import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/services/external_data_service.dart';
import '../../../core/services/google_sheets_service.dart';

class NavigationController extends GetxController {
  late final RxInt currentIndex;
  late final PageController pageController;

  NavigationController() {
    final args = Get.arguments;
    int initialTab = 0;
    if (args is Map && args['tab'] != null) {
      initialTab = args['tab'];
    }
    currentIndex = initialTab.obs;
    pageController = PageController(initialPage: initialTab);
  }

  late WebSocketService _webSocketService;

  // Connection status for UI display
  Rx<ConnectionStatus> get connectionStatus => _webSocketService.connectionStatus;

  @override
  void onInit() {
    super.onInit();
    _initServices();
  }

  Future<void> _initServices() async {
    // Get existing WebSocketService (already initialized in main.dart)
    _webSocketService = Get.find<WebSocketService>();

    // Connect with auth token if available
    final token = await LocalStorage.getAuthToken();
    _webSocketService.connect(token ?? '');

    // Subscribe to essential market data channels
    _subscribeToMarketChannels();

    // Initialize external data services
    _initExternalServices();
  }

  void _subscribeToMarketChannels() {
    // Subscribe to main market data channels
    _webSocketService.subscribe('lme');
    _webSocketService.subscribe('shfe');
    _webSocketService.subscribe('comex');
    _webSocketService.subscribe('fx');
    _webSocketService.subscribe('spot');
    _webSocketService.subscribe('alerts');
  }

  void _initExternalServices() {
    try {
      // Initialize External Data Service (SBI TT, RBI, News, Calendar)
      final externalService = Get.find<ExternalDataService>();
      externalService.initializeAllServices();

      // Initialize Google Sheets Service
      final sheetsService = Get.find<GoogleSheetsService>();
      sheetsService.initialize();
    } catch (e) {
      // Services not available, will use demo data
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  /// Reconnect WebSocket manually
  Future<void> reconnectWebSocket() async {
    final token = await LocalStorage.getAuthToken();
    _webSocketService.disconnect();
    _webSocketService.connect(token ?? '');
    _subscribeToMarketChannels();
  }

  @override
  void onClose() {
    pageController.dispose();
    // Don't disconnect WebSocket here as it's a permanent service
    super.onClose();
  }
}
