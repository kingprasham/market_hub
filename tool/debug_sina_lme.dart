import 'package:http/http.dart' as http;

void main() async {
  // Sina LME Codes (Commonly cited)
  // hf_CAD = LME Copper 3M
  // hf_AHD = LME Aluminum 3M
  // hf_ZSD = LME Zinc 3M
  // hf_PBD = LME Lead 3M
  // hf_NID = LME Nickel 3M
  // hf_SND = LME Tin 3M
  
  final url = Uri.parse('http://hq.sinajs.cn/list=hf_CAD,hf_AHD,hf_ZSD,hf_PBD,hf_NID,hf_SND');
  
  try {
    final response = await http.get(url, headers: {'Referer': 'https://finance.sina.com.cn/'});
    
    print('Status: ${response.statusCode}');
    final parts = response.body.split(';');
    for(final part in parts) {
        print(part.trim()); // Print each var assignment
    }
  } catch (e) {
    print('Error: $e');
  }
}
