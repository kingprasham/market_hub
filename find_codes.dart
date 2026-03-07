import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final queries = ['Platinum', 'Palladium', 'Brent', 'Natural gas', 'WTI'];
  
  for (final q in queries) {
    print('Searching for $q...');
    try {
      final res = await dio.get('https://match.jijinhao.com/k?q=$q');
      print(res.data);
    } catch (e) {
      print('Error $q: $e');
    }
  }
}
