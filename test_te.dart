import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;

void main() async {
  final dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  print('Fetching data...');
  try {
    final response = await dio.get('https://tradingeconomics.com/currencies');
    print('Status code: ${response.statusCode}');
    
    final document = parser.parse(response.data);
    final tables = document.querySelectorAll('table');
    print('Found ${tables.length} tables');
    
    for (final table in tables) {
      final rows = table.querySelectorAll('tr');
      for (final row in rows) {
        final cells = row.querySelectorAll('td, th');
        if (cells.length >= 5) {
          final rawName = cells[1].text.trim().toUpperCase();
          if (['EURUSD', 'GBPUSD', 'USDJPY', 'USDCNY', 'USDINR', 'DXY'].contains(rawName)) {
            print('Row: $rawName | ${cells[2].text.trim()} | ${cells[3].text.trim()} | ${cells[4].text.trim()}');
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
