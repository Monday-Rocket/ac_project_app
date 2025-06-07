import 'package:http/http.dart' as http;

Future<bool> isValidUrl(String url) async {
  try {
    if (url.contains('linkpool://')) return false;

    final result = await http.get(Uri.parse(url));
    return result.statusCode == 200;
  } catch (e) {
    return false;
  }
}
