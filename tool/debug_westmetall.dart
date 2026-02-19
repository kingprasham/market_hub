import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://www.westmetall.com/en/markdaten.php');
  try {
      final response = await http.get(url);
      print('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
          if (response.body.contains('LME-Stocks')) {
              print('Found LME-Stocks!');
          }
          if (response.body.contains('Settlement')) {
              print('Found Settlement!');
          }
          // Print snippet
          print(response.body.substring(0, 500));
      }
  } catch (e) {
      print('Error: $e');
  }
}
