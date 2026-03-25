import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/external_data_service.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../data/models/market/future_data_model.dart';
import '../../../data/models/market/fx_model.dart';
import '../pages/london_lme/controller/london_lme_controller.dart';
import '../pages/china_shfe/controller/china_shfe_controller.dart';
import '../pages/us_comex/controller/us_comex_controller.dart';
import '../pages/fx/controller/fx_controller.dart';
import '../pages/reference_rate/controller/reference_rate_controller.dart';
import '../pages/settlement/controller/settlement_controller.dart';
import '../pages/warehouse_stock/controller/warehouse_stock_controller.dart';

class FutureController extends GetxController with GetSingleTickerProviderStateMixin {
  final selectedTabIndex = 0.obs;

  void _handleArguments() {
    final args = Get.arguments;
    if (args is Map && args['sub_tab'] != null) {
      selectedTabIndex.value = args['sub_tab'];
    }
  }
  final isLoading = true.obs;
  final isRefreshing = false.obs;

  // Data observables
  final lmeData = <FutureDataModel>[].obs;
  final shfeData = <FutureDataModel>[].obs;
  final comexData = <FutureDataModel>[].obs;
  final fxData = <FxModel>[].obs;
  final referenceRates = <FxModel>[].obs;

  // Google Sheets data for city-wise prices
  final delhiPrices = <Map<String, String>>[].obs;
  final mumbaiPrices = <Map<String, String>>[].obs;
  final jamnagarPrices = <Map<String, String>>[].obs;

  StreamSubscription? _dataSubscription;
  WebSocketService? _wsService;
  Timer? _autoRefreshTimer;
  final lastUpdated = Rxn<DateTime>();

  final tabs = ['London', 'China', 'COMEX', 'FX', 'Reference', 'Warehouse', 'Settlement'];

  // Auto-refresh interval (15 seconds)
  static const int refreshIntervalSeconds = 15;

  @override
  void onInit() {
    super.onInit();
    _handleArguments();
    fetchAllData();
    _subscribeToRealTimeUpdates();
    _loadGoogleSheetsData();
    _loadReferenceRatesFromService();
    _startAutoRefresh();
  }

  /// Start auto-refresh timer for real-time updates
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(Duration(seconds: refreshIntervalSeconds), (timer) {
      if (!isLoading.value && !isRefreshing.value) {
        debugPrint('Auto-refreshing future data...');
        fetchAllData();
      }
    });
  }

  void _subscribeToRealTimeUpdates() {
    try {
      _wsService = Get.find<WebSocketService>();

      // Subscribe to specific channels
      _wsService!.subscribe('lme');
      _wsService!.subscribe('shfe');
      _wsService!.subscribe('comex');
      _wsService!.subscribe('fx');

      _dataSubscription = _wsService!.dataStream.listen((update) {
        // Handle channel-specific updates
        switch (update.channel) {
          case 'lme':
            if (update.payload is Map<String, dynamic>) {
              _handleLmeChannelUpdate(update.payload as Map<String, dynamic>);
            }
            break;
          case 'shfe':
            if (update.payload is Map<String, dynamic>) {
              _handleShfeChannelUpdate(update.payload as Map<String, dynamic>);
            }
            break;
          case 'comex':
            if (update.payload is Map<String, dynamic>) {
              _handleComexChannelUpdate(update.payload as Map<String, dynamic>);
            }
            break;
          case 'fx':
            if (update.payload is Map<String, dynamic>) {
              _handleFxChannelUpdate(update.payload as Map<String, dynamic>);
            }
            break;
        }
      });
    } catch (e) {
      // WebSocket not initialized
    }
  }

  void _handleLmeChannelUpdate(Map<String, dynamic> data) {
    final updateData = data['data'] ?? data;
    if (updateData is Map<String, dynamic>) {
      _updateLmeData(updateData);
    }
  }

  void _handleShfeChannelUpdate(Map<String, dynamic> data) {
    final updateData = data['data'] ?? data;
    if (updateData is Map<String, dynamic>) {
      _updateShfeData(updateData);
    }
  }

  void _handleComexChannelUpdate(Map<String, dynamic> data) {
    final updateData = data['data'] ?? data;
    if (updateData is Map<String, dynamic>) {
      _updateComexData(updateData);
    }
  }

  void _handleFxChannelUpdate(Map<String, dynamic> data) {
    final updateData = data['data'] ?? data;
    if (updateData is Map<String, dynamic>) {
      _updateFxData(updateData);
    }
  }

  Future<void> _loadGoogleSheetsData() async {
    try {
      final sheetsService = Get.find<GoogleSheetsService>();

      // Load city-wise prices from Google Sheets
      final delhiSheet = sheetsService.getSheetAsMaps('DELHI');
      final mumbaiSheet = sheetsService.getSheetAsMaps('MUMBAI');
      final jamnagarSheet = sheetsService.getSheetAsMaps('JAMNAGAR');

      if (delhiSheet.isNotEmpty) delhiPrices.assignAll(delhiSheet);
      if (mumbaiSheet.isNotEmpty) mumbaiPrices.assignAll(mumbaiSheet);
      if (jamnagarSheet.isNotEmpty) jamnagarPrices.assignAll(jamnagarSheet);
    } catch (e) {
      // Sheets not available
    }
  }

  Future<void> _loadReferenceRatesFromService() async {
    try {
      final externalService = Get.find<ExternalDataService>();
      final sbiRatesData = externalService.sbiTTRatesValue;
      final rbiRatesData = externalService.rbiReferenceRates;

      if (rbiRatesData.isNotEmpty || sbiRatesData != null) {
        final rates = <FxModel>[];

        // Add RBI rates
        for (final rate in rbiRatesData) {
          rates.add(FxModel(
            pair: 'RBI ${rate.currency}/INR',
            rate: rate.rate,
            change: rate.change,
            changePercent: rate.changePercent,
            lastUpdated: rate.effectiveDate,
            source: 'RBI',
          ));
        }

        // Add SBI TT rates
        if (sbiRatesData != null) {
          for (final rate in sbiRatesData.rates) {
            rates.add(FxModel(
              pair: 'SBI TT Buy ${rate.currency}',
              rate: rate.ttBuyingRate,
              change: rate.ttBuyChange,
              changePercent: rate.ttBuyChangePercent,
              lastUpdated: sbiRatesData.lastUpdated,
              source: 'SBI',
            ));
          }
        }

        if (rates.isNotEmpty) {
          referenceRates.assignAll(rates);
        }
      }
    } catch (e) {
      // External service not available
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    await Future.wait([
      fetchAllData(),
      _loadGoogleSheetsData(),
      _loadReferenceRatesFromService(),
    ]);
    isRefreshing.value = false;
  }

  void _updateLmeData(Map<String, dynamic> update) {
    final index = lmeData.indexWhere((item) => item.symbol == update['symbol']);
    if (index != -1) {
      final old = lmeData[index];
      lmeData[index] = old.copyWith(
        price: update['price']?.toDouble(),
        change: update['change']?.toDouble(),
        changePercent: update['changePercent']?.toDouble(),
        high: update['high']?.toDouble(),
        low: update['low']?.toDouble(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _updateShfeData(Map<String, dynamic> update) {
    final index = shfeData.indexWhere((item) => item.symbol == update['symbol']);
    if (index != -1) {
      final old = shfeData[index];
      shfeData[index] = old.copyWith(
        price: update['price']?.toDouble(),
        change: update['change']?.toDouble(),
        changePercent: update['changePercent']?.toDouble(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _updateComexData(Map<String, dynamic> update) {
    final index = comexData.indexWhere((item) => item.symbol == update['symbol']);
    if (index != -1) {
      final old = comexData[index];
      comexData[index] = old.copyWith(
        price: update['price']?.toDouble(),
        change: update['change']?.toDouble(),
        changePercent: update['changePercent']?.toDouble(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _updateFxData(Map<String, dynamic> update) {
    final index = fxData.indexWhere((item) => item.pair == update['pair']);
    if (index != -1) {
      final old = fxData[index];
      fxData[index] = old.copyWith(
        rate: update['rate']?.toDouble(),
        change: update['change']?.toDouble(),
        changePercent: update['changePercent']?.toDouble(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> fetchAllData() async {
    // Only show loading if we have NO data in any sub-controller yet (initial load)
    // We check Get.isRegistered and then if they have data.
    bool hasAnyData = false;
    try {
      if (Get.isRegistered<LondonLMEController>() && Get.find<LondonLMEController>().metals.isNotEmpty) hasAnyData = true;
      if (!hasAnyData && Get.isRegistered<ChinaSHFEController>() && Get.find<ChinaSHFEController>().metals.isNotEmpty) hasAnyData = true;
      if (!hasAnyData && Get.isRegistered<USComexController>() && Get.find<USComexController>().metals.isNotEmpty) hasAnyData = true;
      if (!hasAnyData && Get.isRegistered<FxController>() && Get.find<FxController>().currencyPairs.isNotEmpty) hasAnyData = true;
    } catch (_) {}

    if (!hasAnyData) {
      isLoading.value = true;
    }

    try {
      // NOTE: Individual page controllers (LondonLMEController, FxController, etc.)
      // now handle data fetching from external APIs (Metals.Dev, Frankfurter, etc.)
      // This central FutureController no longer needs to fetch data
      // The backend api.markethubindia.com does not exist
      
      // Refresh sub-controllers if they are active
      try {
        final List<Future<void>> refreshes = [];
        if (Get.isRegistered<LondonLMEController>()) {
          refreshes.add(Get.find<LondonLMEController>().refreshData());
        }
        if (Get.isRegistered<ChinaSHFEController>()) {
          refreshes.add(Get.find<ChinaSHFEController>().refreshData());
        }
        if (Get.isRegistered<USComexController>()) {
          refreshes.add(Get.find<USComexController>().refreshData());
        }
        if (Get.isRegistered<FxController>()) {
          refreshes.add(Get.find<FxController>().refreshData());
        }
        if (Get.isRegistered<ReferenceRateController>()) {
          refreshes.add(Get.find<ReferenceRateController>().refreshData());
        }
        if (Get.isRegistered<SettlementController>()) {
          refreshes.add(Get.find<SettlementController>().refreshData());
        }
        if (Get.isRegistered<WarehouseStockController>()) {
          refreshes.add(Get.find<WarehouseStockController>().refreshData());
        }
        
        if (refreshes.isNotEmpty) {
          await Future.wait(refreshes);
        }
      } catch (e) {
        debugPrint('Error refreshing sub-controllers: $e');
      }

      // Load reference rates and Google Sheets data
      await Future.wait([
        _loadReferenceRatesFromService(),
        _loadGoogleSheetsData(),
      ]);
    } catch (e) {
      debugPrint('Error in fetchAllData: $e');
    } finally {
      lastUpdated.value = DateTime.now();
      isLoading.value = false;
    }
  }

  Future<void> fetchLmeData() async {
    try {
      final response = await ApiClient().get(ApiConstants.lmeData);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => FutureDataModel.fromJson(json))
            .toList();
        lmeData.assignAll(data);
        debugPrint('✅ Loaded ${data.length} LME prices from API');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch LME data from API: $e');
    }
  }

  Future<void> fetchShfeData() async {
    try {
      final response = await ApiClient().get(ApiConstants.shfeData);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => FutureDataModel.fromJson(json))
            .toList();
        shfeData.assignAll(data);
        debugPrint('✅ Loaded ${data.length} SHFE prices from API');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch SHFE data from API: $e');
    }
  }

  Future<void> fetchComexData() async {
    try {
      final response = await ApiClient().get(ApiConstants.comexData);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => FutureDataModel.fromJson(json))
            .toList();
        comexData.assignAll(data);
        debugPrint('✅ Loaded ${data.length} COMEX prices from API');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch COMEX data from API: $e');
    }
  }

  Future<void> fetchFxData() async {
    try {
      final response = await ApiClient().get(ApiConstants.fxRates);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => FxModel.fromJson(json))
            .toList();
        fxData.assignAll(data);
        debugPrint('✅ Loaded ${data.length} FX rates from API');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch FX data from API: $e');
      // Try ExternalDataService for FX data
      try {
        final externalService = Get.find<ExternalDataService>();
        final rbiRates = externalService.rbiReferenceRates;
        if (rbiRates.isNotEmpty) {
          final fxRates = rbiRates.map((rate) {
            return FxModel(
              pair: '${rate.currency}/INR',
              rate: rate.rate,
              change: rate.change,
              changePercent: rate.changePercent,
              lastUpdated: rate.effectiveDate,
              source: 'RBI',
            );
          }).toList();
          fxData.assignAll(fxRates);
          debugPrint('✅ Loaded ${fxRates.length} FX rates from ExternalDataService (RBI)');
          return;
        }
      } catch (serviceError) {
        debugPrint('ExternalDataService not available');
      }
    }
  }

  Future<void> fetchReferenceRates() async {
    // Try to get from ExternalDataService first
    try {
      final externalService = Get.find<ExternalDataService>();
      final rbiRates = externalService.rbiReferenceRates;
      final sbiRates = externalService.sbiTTRatesValue;

      if (rbiRates.isNotEmpty || sbiRates != null) {
        final rates = <FxModel>[];

        // Add RBI rates
        for (final rate in rbiRates) {
          rates.add(FxModel(
            pair: 'RBI ${rate.currency}/INR',
            rate: rate.rate,
            change: rate.change,
            changePercent: rate.changePercent,
            lastUpdated: rate.effectiveDate,
            source: 'RBI',
          ));
        }

        // Add SBI TT rates
        if (sbiRates != null) {
          for (final rate in sbiRates.rates) {
            rates.add(FxModel(
              pair: 'SBI TT ${rate.currency}',
              rate: rate.ttBuyingRate,
              change: rate.ttBuyChange,
              changePercent: rate.ttBuyChangePercent,
              lastUpdated: sbiRates.lastUpdated,
              source: 'SBI',
            ));
          }
        }

        if (rates.isNotEmpty) {
          referenceRates.assignAll(rates);
          debugPrint('✅ Loaded ${rates.length} reference rates from ExternalDataService');
          return;
        }
      }
    } catch (e) {
      debugPrint('ExternalDataService not available: $e');
    }

    // Try API as fallback
    try {
      final response = await ApiClient().get(ApiConstants.referenceRates);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => FxModel.fromJson(json))
            .toList();
        referenceRates.assignAll(data);
        debugPrint('✅ Loaded ${data.length} reference rates from API');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch reference rates from API: $e');
    }
  }

  @override
  void onClose() {
    _dataSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }
}
