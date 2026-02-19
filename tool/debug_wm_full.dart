import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final url = Uri.parse('https://www.westmetall.com/en/markdaten.php');
  print('Fetching $url...');
  final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  });
  
  print('Status: ${response.statusCode}');
  if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final rows = document.querySelectorAll('tr');
      print('Rows: ${rows.length}');
      
      for(var i=0; i<rows.length; i++) {
          final text = rows[i].text.replaceAll('\n', ' ').trim();
          if (text.toLowerCase().contains('copper')) {
             print('Row $i: $text');
             final cells = rows[i].children.map((c) => '[${c.text.trim()}]').join(' ');
             print('Cells: $cells');
          }
      }
  } else {
      print('Body Header: ${response.body.substring(0, 500)}');
  }
}
