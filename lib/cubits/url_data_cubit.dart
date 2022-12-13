import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlLoader {
  static Future<Metadata> loadData(String url) async {
    final response = await http.get(Uri.parse(url));
    final document = MetadataFetch.responseToDocument(response);
    return MetadataParser.openGraph(document);
  }
}
