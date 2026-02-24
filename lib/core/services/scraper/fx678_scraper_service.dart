import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FX678ScraperService {
  static const String _baseUrl = 'https://quote.fx678.com/exchange';

  // Headers to mimic a real browser
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
  };

  /// Fetch and parse LME Data
  Future<List<ScrapedMetal>> fetchLME() async {
    return _fetchAndParse('LME', _lmeMapping);
  }

  /// Fetch and parse SHFE Data (SHFE exchange products)
  Future<List<ScrapedMetal>> fetchSHFE() async {
    final shfeList = await _fetchAndParse('SHFE', _shfeMapping);
    // Also fetch CZCE for Ferro Silicon and Ferro Manganese Silicon (those are CZCE products)
    final czceList = await _fetchAndParse('CZCE', _czceMapping);
    
    final unique = <String, ScrapedMetal>{};
    for (final item in [...shfeList, ...czceList]) {
      unique[item.symbol] = item;
    }
    return unique.values.toList();
  }

  /// Fetch and parse COMEX Data
  Future<List<ScrapedMetal>> fetchCOMEX() async {
    // Primary: Sina Finance (very reliable for COMEX)
    final sinaList = await _fetchSinaCOMEX();
    if (sinaList.isNotEmpty) return sinaList;

    // Fallback to FX678 pages
    final list1 = await _fetchAndParse('COMEX', _comexMapping);
    final list2 = await _fetchAndParse('WGJS', _comexMapping);

    final unique = <String, ScrapedMetal>{};
    for (final item in [...list1, ...list2]) {
      unique[item.symbol] = item;
    }
    return unique.values.toList();
  }

  /// Fetch Dollar Index — returns a single ScrapedMetal or null
  Future<ScrapedMetal?> fetchDollarIndex() async {
    try {
      // Sina Finance provides DXY as USDX
      final url = Uri.parse('http://hq.sinajs.cn/list=USDX,b_DOLAR,hf_DX');
      final response = await http.get(url, headers: {
        'Referer': 'https://finance.sina.com.cn/',
        'User-Agent': 'Mozilla/5.0',
      });

      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        for (final line in lines) {
          if (!line.contains('="') || !line.contains(',')) continue;
          final dataPart = line
              .substring(line.indexOf('"') + 1, line.lastIndexOf('"'))
              .trim();
          if (dataPart.isEmpty) continue;
          final values = dataPart.split(',');
          final price = double.tryParse(values[0]) ?? 0.0;
          if (price == 0) continue;
          final prev = values.length > 7 ? double.tryParse(values[7]) ?? 0.0 : 0.0;
          final change = prev > 0 ? price - prev : 0.0;
          final changePct = prev > 0 ? (change / prev) * 100 : 0.0;
          return ScrapedMetal(
            name: 'Dollar Index',
            symbol: 'DXY',
            price: price,
            change: change,
            changePercent: changePct,
            exchange: 'FX',
          );
        }
      }

      // Fallback: fx678 DXY page
      final fxUrl = Uri.parse('https://quote.fx678.com/symbol/USDX');
      final fxResponse = await http.get(fxUrl, headers: _headers);
      if (fxResponse.statusCode == 200) {
        final doc = parser.parse(fxResponse.body);
        final priceEl = doc.querySelector('.quote_price') ??
            doc.querySelector('[class*="price"]');
        if (priceEl != null) {
          final price = double.tryParse(
                  priceEl.text.trim().replaceAll(',', '')) ??
              0.0;
          if (price > 0) {
            return ScrapedMetal(
              name: 'Dollar Index',
              symbol: 'DXY',
              price: price,
              change: 0,
              changePercent: 0,
              exchange: 'FX',
            );
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Dollar Index fetch error: $e');
      return null;
    }
  }

  /// Fetch from Sina Finance — reliable for major COMEX futures
  Future<List<ScrapedMetal>> _fetchSinaCOMEX() async {
    try {
      // hf_GC=Gold, hf_SI=Silver, hf_HG=Copper, hf_PL=Platinum, hf_PA=Palladium
      // hf_CL=WTI Crude Oil, hf_OIL=Brent Crude Oil, hf_NG=Natural Gas
      final url = Uri.parse(
          'http://hq.sinajs.cn/list=hf_GC,hf_SI,hf_HG,hf_PL,hf_PA,hf_CL,hf_OIL,hf_NG');
      final response = await http.get(url, headers: {
        'Referer': 'https://finance.sina.com.cn/',
        'User-Agent': 'Mozilla/5.0',
      });

      if (response.statusCode != 200) return [];

      const codeMap = {
        'hf_GC':  ('Gold', 'GC', 'COMEX'),
        'hf_SI':  ('Silver', 'SI', 'COMEX'),
        'hf_HG':  ('Copper', 'HG', 'COMEX'),
        'hf_PL':  ('Platinum', 'PL', 'COMEX'),
        'hf_PA':  ('Palladium', 'PA', 'COMEX'),
        'hf_CL':  ('WTI Crude Oil', 'CL', 'NYMEX'),
        'hf_OIL': ('Brent Crude Oil', 'OIL', 'ICE'),
        'hf_NG':  ('Natural Gas', 'NG', 'NYMEX'),
      };

      final List<ScrapedMetal> metals = [];
      final lines = response.body.split('\n');

      for (final line in lines) {
        if (!line.contains('="') || !line.contains(',')) continue;

        // Extract the variable name: "var hq_str_hf_GC" → "hf_GC"
        final eqIndex = line.indexOf('=');
        if (eqIndex < 0) continue;
        final varName = line.substring(0, eqIndex).trim(); // "var hq_str_hf_GC"
        // Find the code key by suffix matching
        String? code;
        for (final key in codeMap.keys) {
          if (varName.endsWith(key)) {
            code = key;
            break;
          }
        }
        if (code == null) continue;

        final dataPart = line
            .substring(eqIndex + 1)
            .replaceAll('"', '')
            .replaceAll(';', '')
            .trim();
        if (dataPart.isEmpty) continue;

        final values = dataPart.split(',');
        if (values.isEmpty) continue;

        double price = double.tryParse(values[0]) ?? 0.0;
        if (price == 0) continue;

        // Sina futures format: [0]=price, [7]=prevClose typically
        final prevClose = values.length > 7 ? double.tryParse(values[7]) ?? 0.0 : 0.0;

        double change = 0;
        double changePct = 0;
        if (prevClose > 0) {
          change = price - prevClose;
          changePct = (change / prevClose) * 100;
        }

        // HG (Copper) is quoted in cents/lb on Sina → convert to USD/lb
        if (code == 'hf_HG') {
          price = price / 100;
          change = change / 100;
        }

        final info = codeMap[code]!;
        metals.add(ScrapedMetal(
          name: info.$1,
          symbol: info.$2,
          price: price,
          change: change,
          changePercent: changePct,
          exchange: info.$3,
        ));
      }
      debugPrint('Sina COMEX scraped ${metals.length} items');
      return metals;
    } catch (e) {
      debugPrint('Sina Scraper Error: $e');
      return [];
    }
  }

  /// Fetch and parse Main Metals
  Future<List<ScrapedMetal>> fetchMainMetals() async {
    return _fetchAndParse('MAINMETAL', _mainMetalMapping);
  }

  Future<List<ScrapedMetal>> _fetchAndParse(
      String exchange, Map<String, String> nameMapping) async {
    try {
      final url = Uri.parse('$_baseUrl/$exchange');
      debugPrint('Fetching $url...');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch $exchange: ${response.statusCode}');
        return [];
      }

      final document = parser.parse(response.body);
      final List<ScrapedMetal> metals = [];

      final rows = document.querySelectorAll('tr');

      for (final row in rows) {
        final cells = row.children;
        if (cells.length < 4) continue;

        final nameText = cells[0].text.trim();

        String? englishName;
        String? symbol;

        for (final key in nameMapping.keys) {
          if (nameText.contains(key)) {
            englishName = nameMapping[key];
            symbol = _getSymbol(englishName!);
            break;
          }
        }

        if (englishName == null) continue;

        try {
          final priceStr = cells[1].text.trim();
          final price = double.tryParse(priceStr.replaceAll(',', '')) ?? 0.0;

          final changeStr = cells[2].text.trim();
          final change = double.tryParse(changeStr) ?? 0.0;

          final changePctStr =
              cells[3].text.trim().replaceAll('%', '');
          final changePct = double.tryParse(changePctStr) ?? 0.0;

          double high = 0;
          double low = 0;
          double prevHigh = 0;
          double prevLow = 0;
          double open = 0;
          double prev = 0;
          double stock = 0;
          double settlement = 0;

          if (cells.length > 4) {
            high = double.tryParse(cells[4].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 5) {
            low = double.tryParse(cells[5].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 6) {
            open = double.tryParse(cells[6].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 7) {
            prev = double.tryParse(cells[7].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 9) {
            stock = double.tryParse(cells[9].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 10) {
            settlement = double.tryParse(cells[10].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 11) {
            prevHigh = double.tryParse(cells[11].text.trim().replaceAll(',', '')) ?? 0.0;
          }
          if (cells.length > 12) {
            prevLow = double.tryParse(cells[12].text.trim().replaceAll(',', '')) ?? 0.0;
          }

          metals.add(ScrapedMetal(
            name: englishName,
            symbol: symbol ?? '',
            price: price,
            change: change,
            changePercent: changePct,
            high: high,
            low: low,
            open: open,
            prev: prev,
            prevHigh: prevHigh,
            prevLow: prevLow,
            stock: stock,
            settlement: settlement,
            exchange: exchange,
          ));
        } catch (e) {
          debugPrint('Error parsing row for $englishName: $e');
        }
      }

      debugPrint('Scraped ${metals.length} items for $exchange');
      return metals;
    } catch (e) {
      debugPrint('Error scraping $exchange: $e');
      return [];
    }
  }

  String _getSymbol(String name) {
    if (name.contains('Copper')) return 'CU';
    if (name.contains('Aluminium') || name.contains('Aluminum')) return 'AL';
    if (name.contains('Zinc')) return 'ZN';
    if (name.contains('Lead')) return 'PB';
    if (name.contains('Nickel')) return 'NI';
    if (name.contains('Tin')) return 'SN';
    if (name.contains('Gold')) return 'AU';
    if (name.contains('Silver')) return 'AG';
    if (name.contains('Ferro Silicon')) return 'SF';
    if (name.contains('Ferro Manganese') || name.contains('Ferro Mn')) return 'SM';
    if (name.contains('Stainless') || name.contains('SS')) return 'SS';
    if (name.contains('Wire Rod') || name.contains('WR')) return 'WR';
    if (name.contains('Rebar')) return 'RB';
    if (name.contains('AA') || name.contains('Alloy')) return 'AA';
    if (name.contains('Rubber')) return 'RU';
    if (name.contains('WTI')) return 'CL';
    if (name.contains('Brent')) return 'OIL';
    if (name.contains('Natural Gas')) return 'NG';
    if (name.contains('Platinum')) return 'PL';
    if (name.contains('Palladium')) return 'PA';
    if (name.contains('Dollar Index') || name.contains('DXY')) return 'DXY';
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  // Mappings (Chinese → English)
  static const _lmeMapping = {
    'LME铜': 'LME Copper',
    'LME铝': 'LME Aluminium',
    'LME锌': 'LME Zinc',
    'LME铅': 'LME Lead',
    'LME镍': 'LME Nickel',
    'LME锡': 'LME Tin',
    'LME合金': 'LME AA',
    'LME铝合金': 'LME AA',
    '北美特种合金': 'LME AA',
  };

  static const _shfeMapping = {
    '沪铜连续': 'SHFE Copper',
    '沪铝连续': 'SHFE Aluminium',
    '沪锌连续': 'SHFE Zinc',
    '沪铅连续': 'SHFE Lead',
    '沪镍连续': 'SHFE Nickel',
    '沪锡连续': 'SHFE Tin',
    '沪金连续': 'SHFE Gold',
    '沪银连续': 'SHFE Silver',
    '不锈钢连续': 'SHFE SS',
    '线材连续': 'SHFE WR',
    '螺纹连续': 'SHFE Rebar',
    '橡胶连续': 'SHFE Rubber',
  };

  /// CZCE products — Ferro Silicon (SF) and Ferro Manganese Silicon (SM)
  static const _czceMapping = {
    '硅铁连续': 'SHFE Ferro Silicon',
    '锰硅连续': 'SHFE Ferro Manganese Silicon',
  };

  static const _comexMapping = {
    'COMEX铜': 'COMEX Copper',
    'COMEX黄金': 'COMEX Gold',
    'COMEX白银': 'COMEX Silver',
    '美铜': 'COMEX Copper',
    '美黄金': 'COMEX Gold',
    '美白银': 'COMEX Silver',
    '纽约铜': 'COMEX Copper',
    '纽约金': 'COMEX Gold',
    '美铂金': 'Platinum',
    '美钯金': 'Palladium',
    'WTI': 'WTI Crude Oil',
    '美原油': 'WTI Crude Oil',
    '纽约原油': 'WTI Crude Oil',
    '布伦特': 'Brent Crude Oil',
    'Brent': 'Brent Crude Oil',
    '天然气': 'Natural Gas',
    '美天然气': 'Natural Gas',
  };

  static const _mainMetalMapping = {
    '现货': 'Spot',
  };
}

class ScrapedMetal {
  final String name;
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double open;
  final double prev;
  final double prevHigh;
  final double prevLow;
  final double stock;
  final double settlement;
  final String exchange;

  ScrapedMetal({
    required this.name,
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    this.high = 0,
    this.low = 0,
    this.open = 0,
    this.prev = 0,
    this.prevHigh = 0,
    this.prevLow = 0,
    this.stock = 0,
    this.settlement = 0,
    required this.exchange,
  });
}
