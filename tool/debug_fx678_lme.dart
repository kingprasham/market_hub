import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final url = Uri.parse('https://quote.fx678.com/exchange/LME');
  try {
    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
    
    if (response.statusCode == 200) {
       final document = parser.parse(response.body);
       final rows = document.querySelectorAll('tr');
       print('Total Rows: ${rows.length}');
       
       if (rows.isNotEmpty) {
           // Print Header with Index
           final headerCells = rows[0].children;
           for(var i=0; i<headerCells.length; i++) {
               print('$i: ${headerCells[i].text.trim()}');
           }
           
           // Print first row
           if (rows.length > 1) {
               final firstCells = rows[1].children;
               for(var i=0; i<firstCells.length; i++) {
                   print('Data $i: ${firstCells[i].text.trim()}');
               }
           }
       }
    } else {
        print('Failed: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
