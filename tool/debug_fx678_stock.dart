import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final url = Uri.parse('https://quote.fx678.com/exchange/LME');
  print('Fetching $url...');
  final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  });
  
  if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final rows = document.querySelectorAll('tr');
      print('Rows: ${rows.length}');
      
      for(var i=0; i<rows.length; i++) {
          final cells = rows[i].children.map((c) => c.text.trim()).toList();
          print('Row $i: $cells');
      }
  } else {
      print('Failed: ${response.statusCode}');
  }
}
