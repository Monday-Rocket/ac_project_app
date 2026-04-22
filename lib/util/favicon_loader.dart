import 'package:http/http.dart' as http;

/// 주어진 페이지 URL에서 favicon을 찾아 반환한다.
///
/// 우선순위:
/// 1. `<link rel="apple-touch-icon" ...>` (고해상도, 보통 180px)
/// 2. `<link rel="icon"|"shortcut icon" ...>`
/// 3. `<도메인>/favicon.ico` (도메인 루트 폴백)
///
/// 실패 시 `null`.
class FaviconLoader {
  static const Duration _timeout = Duration(seconds: 5);

  static Future<String?> fetch(
    String pageUrl, {
    http.Client? client,
  }) async {
    final pageUri = _tryParseHttp(pageUrl);
    if (pageUri == null) return null;

    final httpClient = client ?? http.Client();
    final ownsClient = client == null;

    try {
      final response = await httpClient
          .get(pageUri, headers: const {'User-Agent': _userAgent})
          .timeout(_timeout);

      if (response.statusCode >= 500) return null;

      final html = _looksLikeHtml(response) ? response.body : '';
      final hinted = _extractIconHref(html, preferAppleTouch: true) ??
          _extractIconHref(html, preferAppleTouch: false);

      if (hinted != null) {
        final resolved = _resolve(pageUri, hinted);
        if (resolved != null) return resolved;
      }

      return _defaultFavicon(pageUri);
    } catch (_) {
      return null;
    } finally {
      if (ownsClient) httpClient.close();
    }
  }

  static Uri? _tryParseHttp(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri;
  }

  static bool _looksLikeHtml(http.Response response) {
    final type = response.headers['content-type'] ?? '';
    if (type.contains('text/html')) return true;
    if (type.isEmpty) {
      // content-type 없으면 body 앞부분으로 추측
      final head = response.body.trimLeft().toLowerCase();
      return head.startsWith('<!doctype') || head.startsWith('<html');
    }
    return false;
  }

  /// HTML에서 `<link rel="..." href="...">` 태그를 찾아 첫 매칭의 href 반환.
  static String? _extractIconHref(
    String html, {
    required bool preferAppleTouch,
  }) {
    if (html.isEmpty) return null;

    // <link ...> 태그만 훑어서 rel/href를 뽑는다.
    final linkTagRegex = RegExp(
      r'<link\b[^>]*>',
      caseSensitive: false,
    );
    final attrRegex = RegExp(
      r'''(\w[\w-]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
      caseSensitive: false,
    );

    for (final tagMatch in linkTagRegex.allMatches(html)) {
      final tag = tagMatch.group(0)!;
      String? rel;
      String? href;
      for (final attr in attrRegex.allMatches(tag)) {
        final name = attr.group(1)!.toLowerCase();
        final value = attr.group(2) ?? attr.group(3) ?? attr.group(4) ?? '';
        if (name == 'rel') rel = value.toLowerCase().trim();
        if (name == 'href') href = value.trim();
      }
      if (rel == null || href == null || href.isEmpty) continue;

      final isAppleTouch = rel.split(RegExp(r'\s+')).contains('apple-touch-icon');
      final isIcon = rel == 'icon' ||
          rel == 'shortcut icon' ||
          rel.split(RegExp(r'\s+')).contains('icon');

      if (preferAppleTouch && isAppleTouch) return href;
      if (!preferAppleTouch && isIcon && !isAppleTouch) return href;
    }
    return null;
  }

  static String? _resolve(Uri base, String href) {
    // protocol-relative: //cdn.example.com/x.png
    if (href.startsWith('//')) {
      return '${base.scheme}:$href';
    }
    final parsed = Uri.tryParse(href);
    if (parsed == null) return null;
    if (parsed.isAbsolute) return parsed.toString();
    return base.resolveUri(parsed).toString();
  }

  static String _defaultFavicon(Uri base) {
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/favicon.ico',
    ).toString();
  }

  static const String _userAgent =
      'Mozilla/5.0 (compatible; LinkpoolBot/1.0)';
}
