import 'dart:async';
import 'package:http/http.dart' as http;

class LinkCheckResult {
  const LinkCheckResult({
    required this.url,
    required this.status,
    required this.ok,
  });

  final String url;
  final int? status;
  final bool ok;
}

class LinkChecker {
  static const int _batchSize = 10;
  static const Duration _timeout = Duration(seconds: 5);

  static Future<LinkCheckResult> _checkUrl(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
      ).timeout(_timeout);
      return LinkCheckResult(
        url: url,
        status: response.statusCode,
        ok: response.statusCode >= 200 && response.statusCode < 400,
      );
    } on Exception catch (_) {
      return LinkCheckResult(url: url, status: null, ok: false);
    }
  }

  static Future<List<LinkCheckResult>> checkLinks(
    List<String> urls, {
    void Function(int checked, int total)? onProgress,
  }) async {
    final results = <LinkCheckResult>[];

    for (var i = 0; i < urls.length; i += _batchSize) {
      final batch = urls.sublist(
        i,
        i + _batchSize > urls.length ? urls.length : i + _batchSize,
      );
      final batchResults = await Future.wait(batch.map(_checkUrl));
      results.addAll(batchResults);
      onProgress?.call(results.length, urls.length);
    }

    return results;
  }
}
