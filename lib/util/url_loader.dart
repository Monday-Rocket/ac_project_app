import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlLoader {
  static Future<Metadata> loadData(String url) async {
    final dio = Dio(
      BaseOptions(
        followRedirects: true,
        responseType: ResponseType.plain,
      ),
    );
    final tempResponse = await dio.get<dynamic>(
      url,
      options: Options(
        headers: {'User-Agent': 'facebookexternalhit/1.1'},
      ),
    );

    if (tempResponse.redirects.isNotEmpty) {
      final redirectPath = tempResponse.redirects.last.location.toString();

      final queryMap = Uri.parse(redirectPath).queryParametersAll;
      if (queryMap.containsKey('url')) {
        final redirectUrls = queryMap['url'];
        if (redirectUrls != null) {
          return _getMetadata(redirectUrls[0], url);
        }
      }
    }
    return _getMetadata(url, url);
  }

  static Future<Metadata> _getMetadata(String url, String realUrl) async {
    final extractedMetadata = await _extract(url, realUrl);
    if (extractedMetadata == null) {
      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'facebookexternalhit/1.1'});
      final document = MetadataFetch.responseToDocument(response);
      final openGraph = MetadataParser.openGraph(document)..url = realUrl;
      return openGraph;
    } else {
      return extractedMetadata;
    }
  }

  static Future<Metadata?> _extract(String url, String realUrl) async {
    try {
      final metadata = await MetadataFetch.extract(url);
      if (metadata != null) {
        metadata.url = realUrl;
      }
      return metadata;
    } catch (e) {
      return null;
    }
  }

  static bool isValidateUrl(String url) {
    return Uri.parse(url).isAbsolute;
  }
}
