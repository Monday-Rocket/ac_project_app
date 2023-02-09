import 'package:http/http.dart' as http;

Future<bool> isValidUrl(String url) async {
  final result = await http.get(Uri.parse(url));
  return result.statusCode == 200;
}
