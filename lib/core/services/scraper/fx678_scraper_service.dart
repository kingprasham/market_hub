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

  /// Fetch and parse SHFE Data
  Future<List<ScrapedMetal>> fetchSHFE() async {
    return _fetchAndParse('SHFE', _shfeMapping);
  }

  /// Fetch and parse COMEX Data
  Future<List<ScrapedMetal>> fetchCOMEX() async {
    // Check multiple sources but prioritize Sina (reliable for COMEX)
    final sinaList = await _fetchSinaCOMEX();
    if (sinaList.isNotEmpty) return sinaList;
    
    // Fallback to FX678 pages
    final list1 = await _fetchAndParse('COMEX', _comexMapping);
    final list2 = await _fetchAndParse('WGJS', _comexMapping); 
    
    final unique = <String, ScrapedMetal>{};
    for (final item in [...sinaList, ...list1, ...list2]) {
      unique[item.symbol] = item;
    }
    return unique.values.toList();
  }

  /// Fetch from Sina Finance (Very reliable for Futures)
  Future<List<ScrapedMetal>> _fetchSinaCOMEX() async {
    try {
      // hf_GC=Gold, hf_SI=Silver, hf_HG=Copper, hf_PL=Platinum, hf_PA=Palladium
      final url = Uri.parse('http://hq.sinajs.cn/list=hf_GC,hf_SI,hf_HG,hf_PL,hf_PA');
      final response = await http.get(url, headers: {
        'Referer': 'https://finance.sina.com.cn/',
        'User-Agent': 'Mozilla/5.0'
      });
      
      if (response.statusCode != 200) return [];
      
      final List<ScrapedMetal> metals = [];
      const codeMap = {
        'hf_GC': ('Gold', 'GC'),
        'hf_SI': ('Silver', 'SI'),
        'hf_HG': ('Copper', 'HG'),
        'hf_PL': ('Platinum', 'PL'),
        'hf_PA': ('Palladium', 'PA'),
      };

      // Format: var hq_str_hf_GC="Price,Bid,Ask,High,Low,Time,PrevClose,Open,Holdings,Date,Name,etc";
      // Actually standard futures format varies, but usually 0 is price.
      // Let's protect against index errors.
      
      final lines = response.body.split('\n');
      for (final line in lines) {
        if (!line.contains('=')) continue;
        
        final parts = line.split('=');
        final codePart = parts[0].trim(); // var hq_str_hf_GC
        final code = codePart.substring(codePart.length - 5); // hf_GC
        
        final dataPart = parts[1].replaceAll('"', '').replaceAll(';', '').trim();
        final values = dataPart.split(',');
        
        if (values.isEmpty) continue;
        
        final info = codeMap[code];
        if (info == null) continue;
        
        double price = double.tryParse(values[0]) ?? 0.0;
        final prevClose = (values.length > 7) ? double.tryParse(values[7]) ?? 0.0 : 0.0; // Index 7 often prev close
        // Note: verify indices if change is wrong. For now calc change manually if prev exist
        
        // Sina Futures Format: 
        // 0: Current Price
        // 1: ?
        // 2: ?
        // 3: ? 
        // 4: ?
        // 5: ?
        // 6: Time
        // 7: Prev Settlement/Close?
        // 8: Open
        // 9: High
        // 10: Low
        // 11: Date
        // 12: Name
        
        // If price is 0, skip
        if (price == 0) continue;
        
        double change = 0;
        double changePct = 0;
        
        if (prevClose > 0) {
          change = price - prevClose;
          changePct = (change / prevClose) * 100;
        }

        // Special handling for Copper (HG) which is quoted in Cents via Sina
        if (code == 'hf_HG') {
          price = price / 100;
          change = change / 100;
          // changePercent logic remains same (ratio)
        }
  
        metals.add(ScrapedMetal(
          name: 'COMEX ${info.$1}',
          symbol: info.$2,
          price: price,
          change: change,
          changePercent: changePct,
          exchange: 'COMEX',
        ));
      }
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

  Future<List<ScrapedMetal>> _fetchAndParse(String exchange, Map<String, String> nameMapping) async {
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
      
      // FX678 usually puts data in a table with id 'hqp_table' or class 'hqp_table'
      // We look for all rows
      final rows = document.querySelectorAll('tr');
      
      for (final row in rows) {
        final cells = row.children;
        // Typically: Name, Last, Change, Change%, High, Low...
        // We need at least sufficient columns
        if (cells.length < 4) continue;
        
        final nameText = cells[0].text.trim();
        
        // Check if this row is for a metal we care about (in our mapping)
        // Fuzzy match: if the name contains a key in our mapping
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
            // Parse numerical values
            // Typically col 1 is Last Price
            final priceStr = cells[1].text.trim();
            final price = double.tryParse(priceStr.replaceAll(',', '')) ?? 0.0;
            
            // Col 2 is Change
            final changeStr = cells[2].text.trim();
            final change = double.tryParse(changeStr) ?? 0.0;
            
            // Col 3 is Change %
            final changePctStr = cells[3].text.trim().replaceAll('%', '');
            final changePct = double.tryParse(changePctStr) ?? 0.0;

            double high = 0;
            double low = 0;
            double open = 0;
            double prev = 0;
            double stock = 0;
            double settlement = 0;

            // Try parsing extra columns if available
            // Standard layout: Name | Last | Chg | % | High | Low | Open | Prev | Vol | Stock | Settle
            if (cells.length > 4) high = double.tryParse(cells[4].text.trim().replaceAll(',', '')) ?? 0.0;
            if (cells.length > 5) low = double.tryParse(cells[5].text.trim().replaceAll(',', '')) ?? 0.0;
            if (cells.length > 6) open = double.tryParse(cells[6].text.trim().replaceAll(',', '')) ?? 0.0;
            if (cells.length > 7) prev = double.tryParse(cells[7].text.trim().replaceAll(',', '')) ?? 0.0;
            // Skip Vol (8)
            if (cells.length > 9) stock = double.tryParse(cells[9].text.trim().replaceAll(',', '')) ?? 0.0;
            if (cells.length > 10) settlement = double.tryParse(cells[10].text.trim().replaceAll(',', '')) ?? 0.0;

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
    if (name.contains('Aluminium')) return 'AL';
    if (name.contains('Zinc')) return 'ZN';
    if (name.contains('Lead')) return 'PB';
    if (name.contains('Nickel')) return 'NI';
    if (name.contains('Tin')) return 'SN';
    if (name.contains('Gold')) return 'AU';
    if (name.contains('Silver')) return 'AG';
    return name.substring(0, 2).toUpperCase();
  }

  // Mappings (Chinese -> English)
  static const _lmeMapping = {
    'LME铜': 'LME Copper',
    'LME铝': 'LME Aluminium',
    'LME锌': 'LME Zinc',
    'LME铅': 'LME Lead',
    'LME镍': 'LME Nickel',
    'LME锡': 'LME Tin',
    'LME合金': 'LME Alloy',
  };

  static const _shfeMapping = {
    '沪铜': 'SHFE Copper',
    '沪铝': 'SHFE Aluminium',
    '沪锌': 'SHFE Zinc',
    '沪铅': 'SHFE Lead',
    '沪镍': 'SHFE Nickel',
    '沪锡': 'SHFE Tin',
    '沪金': 'SHFE Gold',
    '沪银': 'SHFE Silver',
    '螺纹': 'Rebar',
    '橡胶': 'Rubber',
  };

  static const _comexMapping = {
    'COMEX铜': 'COMEX Copper',
    'COMEX黄金': 'COMEX Gold',
    'COMEX白银': 'COMEX Silver',
    '美铜': 'COMEX Copper', // Alternative name
    '美黄金': 'COMEX Gold', // Alternative name
    '美白银': 'COMEX Silver', // Alternative name
    '纽约铜': 'COMEX Copper',
    '纽约金': 'COMEX Gold',
  };

  static const _mainMetalMapping = {
    '现货': 'Spot',
    // Add logic to pick up main contracts if they appear here
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
    this.stock = 0,
    this.settlement = 0,
    required this.exchange,
  });
}
