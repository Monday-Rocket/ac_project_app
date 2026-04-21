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

/// 단순 취소 플래그. `cancel()` 호출 이후 진행 중인 `checkLinks` 는
/// 현재 배치를 마치면 남은 작업을 건너뛰고 수집된 결과만 반환한다.
class LinkCheckCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() {
    _cancelled = true;
  }
}

class LinkChecker {
  static const int _batchSize = 10;
  static const Duration _timeout = Duration(seconds: 5);

  static Future<LinkCheckResult> _checkUrl(
    String url,
    http.Client client,
  ) async {
    final uri = _tryParse(url);
    if (uri == null) {
      return LinkCheckResult(url: url, status: null, ok: false);
    }

    try {
      final headResp = await client.head(uri).timeout(_timeout);
      if (_isOk(headResp.statusCode)) {
        return LinkCheckResult(url: url, status: headResp.statusCode, ok: true);
      }

      if (_shouldTryGetFallback(headResp.statusCode)) {
        final getResp = await client.get(uri).timeout(_timeout);
        return LinkCheckResult(
          url: url,
          status: getResp.statusCode,
          ok: _isOk(getResp.statusCode),
        );
      }

      return LinkCheckResult(url: url, status: headResp.statusCode, ok: false);
    } on Exception catch (_) {
      try {
        final getResp = await client.get(uri).timeout(_timeout);
        return LinkCheckResult(
          url: url,
          status: getResp.statusCode,
          ok: _isOk(getResp.statusCode),
        );
      } on Exception catch (_) {
        return LinkCheckResult(url: url, status: null, ok: false);
      }
    }
  }

  static bool _isOk(int status) => status >= 200 && status < 400;

  static bool _shouldTryGetFallback(int status) =>
      status == 405 || status == 403 || status == 501;

  static Uri? _tryParse(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return null;
      }
      return uri;
    } on FormatException {
      return null;
    }
  }

  static Future<List<LinkCheckResult>> checkLinks(
    List<String> urls, {
    void Function(int checked, int total)? onProgress,
    http.Client? client,
    LinkCheckCancelToken? cancelToken,
  }) async {
    if (urls.isEmpty) return const [];

    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    final total = urls.length;
    final results = List<LinkCheckResult?>.filled(total, null);
    var completed = 0;

    try {
      for (var i = 0; i < total; i += _batchSize) {
        if (cancelToken?.isCancelled ?? false) break;
        final end = i + _batchSize > total ? total : i + _batchSize;
        final futures = <Future<void>>[];
        for (var j = i; j < end; j++) {
          final index = j;
          futures.add(
            _checkUrl(urls[index], httpClient).then((result) {
              results[index] = result;
              completed += 1;
              if (!(cancelToken?.isCancelled ?? false)) {
                onProgress?.call(completed, total);
              }
            }),
          );
        }
        await Future.wait(futures);
      }
    } finally {
      if (ownsClient) httpClient.close();
    }

    return results.whereType<LinkCheckResult>().toList();
  }
}
