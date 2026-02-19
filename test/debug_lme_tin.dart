import 'package:flutter_test/flutter_test.dart';
import 'package:market_hub_new/core/services/scraper/fx678_scraper_service.dart';

void main() {
  test('Verify LME Tin Price', () async {
    final scraper = FX678ScraperService();
    
    print('--- Fetching LME Data ---');
    final lme = await scraper.fetchLME();
    final tin = lme.firstWhere((m) => m.name.contains('Tin'), orElse: () => ScrapedMetal(name: 'Not Found', symbol: '', price: 0, change: 0, changePercent: 0, exchange: ''));
    
    print('LME Tin Price: ${tin.price}');
    print('All LME Items: ${lme.map((e) => "${e.name}:${e.price}").join(", ")}');
  });
}
