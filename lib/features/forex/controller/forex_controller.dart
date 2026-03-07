import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/sbi_forex_service.dart';
import '../../../data/models/forex/sbi_forex_rate_model.dart';

class ForexController extends GetxController {
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final dataSource = 'Loading...'.obs;
  
  // Rate type for display (can be toggled)
  final rateType = 'TT'.obs; // TT, BILL, TRAVEL_CARD, CN
  
  // Filter state
  final selectedFilter = 'Popular'.obs;
  final filterOptions = [
    'Popular', 
    'All', 
    'Asia', 
    'Europe', 
    'Middle East', 
    'Americas',
    'Others'
  ];

  // Data storage
  // Map of currency code -> Latest rate model
  final currencyRates = <String, SbiForexRateModel>{}.obs;
  
  // Last update time
  final lastUpdated = Rxn<DateTime>();

  SbiForexService? _forexService;

  final rateTypes = {
    'TT': 'Telegraph Transfer',
    'BILL': 'Bill',
    'TRAVEL_CARD': 'Travel Card',
    'CN': 'Currency Note',
  };
  
  // Region definitions
  final _asiaCurrencies = {'JPY', 'CNY', 'HKD', 'IDR', 'KRW', 'MYR', 'SGD', 'THB', 'BDT', 'LKR', 'PKR'};
  final _europeCurrencies = {'EUR', 'GBP', 'CHF', 'DKK', 'NOK', 'SEK', 'RUB', 'TRY'};
  final _middleEastCurrencies = {'AED', 'BHD', 'KWD', 'OMR', 'QAR', 'SAR'};
  final _americasCurrencies = {'USD', 'CAD'};

  @override
  void onInit() {
    super.onInit();
    _initService();
    loadAllRates();
  }

  void _initService() {
    try {
      _forexService = Get.find<SbiForexService>();
    } catch (e) {
      debugPrint('SbiForexService not found, creating new instance');
      _forexService = Get.put(SbiForexService());
    }
  }

  Future<void> loadAllRates() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      // Get all supported currency codes
      final allCodes = SupportedCurrencies.currencyCodes;
      
      // Fetch data for all currencies
      // We use fetchMultipleCurrencies which returns Map<String, List<SbiForexRateModel>>
      // We only need the latest rate for the list view
      final results = await _forexService!.fetchMultipleCurrencies(allCodes);
      
      final newRates = <String, SbiForexRateModel>{};
      
      results.forEach((code, rates) {
        if (rates.isNotEmpty) {
          var currentRate = rates.first;
          
          // Calculate change if previous data exists
          if (rates.length > 1) {
            final prevRate = rates[1];
            // Use TT Sell as the standard reference for change
            final currentPrice = currentRate.ttSell ?? 0;
            final prevPrice = prevRate.ttSell ?? 0;
            
            if (currentPrice > 0 && prevPrice > 0) {
              final change = currentPrice - prevPrice;
              final percentChange = (change / prevPrice) * 100;
              
              currentRate = currentRate.copyWith(
                change: change,
                percentChange: percentChange,
              );
            }
          }
          
          newRates[code] = currentRate;
        }
      });
      
      if (newRates.isEmpty && currencyRates.isNotEmpty) {
        // Keep existing rates on fetch failure/empty
        dataSource.value = 'Data Unavailable'; 
      } else if (newRates.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'No forex data available';
      } else {
        currencyRates.assignAll(newRates);
        lastUpdated.value = DateTime.now();
      }
      
    } catch (e) {
      debugPrint('Error loading forex rates: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to load forex rates. Please check your connection.';
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void changeRateType(String type) {
    rateType.value = type;
  }

  Future<void> refreshData() async {
    _forexService?.clearAllCache();
    await loadAllRates();
  }
  
  // Get filtered list of currencies for display
  List<SbiForexRateModel> get filteredCurrencies {
    if (currencyRates.isEmpty) return [];
    
    List<SbiForexRateModel> result = [];
    
    switch (selectedFilter.value) {
      case 'All':
        result = currencyRates.values.toList();
        break;
        
      case 'Popular':
        for (var code in SupportedCurrencies.popularCurrencies) {
          if (currencyRates.containsKey(code)) {
            result.add(currencyRates[code]!);
          }
        }
        break;
        
      case 'Asia':
        for (var code in _asiaCurrencies) {
          if (currencyRates.containsKey(code)) {
            result.add(currencyRates[code]!);
          }
        }
        break;
        
      case 'Europe':
        for (var code in _europeCurrencies) {
          if (currencyRates.containsKey(code)) {
            result.add(currencyRates[code]!);
          }
        }
        break;
        
      case 'Middle East':
        for (var code in _middleEastCurrencies) {
          if (currencyRates.containsKey(code)) {
            result.add(currencyRates[code]!);
          }
        }
        break;
        
      case 'Americas':
        for (var code in _americasCurrencies) {
          if (currencyRates.containsKey(code)) {
            result.add(currencyRates[code]!);
          }
        }
        break;
        
      case 'Others':
        // Everything else
        currencyRates.forEach((code, rate) {
          if (!_asiaCurrencies.contains(code) && 
              !_europeCurrencies.contains(code) && 
              !_middleEastCurrencies.contains(code) && 
              !_americasCurrencies.contains(code)) {
            result.add(rate);
          }
        });
        break;
        
      default:
        result = currencyRates.values.toList();
    }
    
    // Sort by currency code if not popular (popular has its own order)
    if (selectedFilter.value != 'Popular') {
      result.sort((a, b) => a.currencyCode.compareTo(b.currencyCode));
    }
    
    return result;
  }

  /// Get buy rate value based on selected rate type
  double? getBuyRate(SbiForexRateModel rate) {
    switch (rateType.value) {
      case 'TT': return rate.ttBuy;
      case 'BILL': return rate.billBuy;
      case 'TRAVEL_CARD': return rate.forexTravelCardBuy;
      case 'CN': return rate.cnBuy;
      default: return rate.ttBuy;
    }
  }
  
  /// Get sell rate value based on selected rate type
  double? getSellRate(SbiForexRateModel rate) {
    switch (rateType.value) {
      case 'TT': return rate.ttSell;
      case 'BILL': return rate.billSell;
      case 'TRAVEL_CARD': return rate.forexTravelCardSell;
      case 'CN': return rate.cnSell;
      default: return rate.ttSell;
    }
  }

  /// Check if a rate type is available for a specific currency
  bool isRateTypeAvailable(SbiForexRateModel rate) {
    final buy = getBuyRate(rate);
    final sell = getSellRate(rate);
    return buy != null || sell != null;
  }
}
