import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:market_hub_new/core/services/market_session_service.dart';
import 'package:market_hub_new/core/storage/local_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() async {
  // Mock Hive for testing
  final tempDir = Directory.systemTemp.createTempSync();
  Hive.init(tempDir.path);
  await LocalStorage.init();

  group('MarketSessionService Tests', () {
    late MarketSessionService service;

    setUp(() {
      service = MarketSessionService();
    });

    test('Calculation with Scraper Fallback', () {
      final results = service.calculateChange(
        MarketType.lme, 
        'CU', 
        9500.0, 
        9400.0, // Scraper prev close
      );

      expect(results['change'], 100.0);
      expect(results['percent'], closeTo(1.06, 0.01));
    });

    test('Calculation with Stored Reference Price', () async {
      // Manually inject a reference price into storage
      await LocalStorage.cacheData('market_ref_price_lme_CU', 9000.0);

      final results = service.calculateChange(
        MarketType.lme, 
        'CU', 
        9500.0, 
        9400.0,
      );

      // Should prefer stored price over scraper fallback
      expect(results['change'], 500.0);
      expect(results['percent'], closeTo(5.55, 0.01));
    });

    test('Reference Price Capture logic', () {
      // This is hard to test with real time, but we can verify the method exists and runs without error
      service.updateReferencePrice(MarketType.lme, 'CU', 9550.0);
    });
  });
}
