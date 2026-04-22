import 'package:ac_project_app/util/favicon_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('FaviconLoader', () {
    test('apple-touch-icon 있으면 그 URL 반환', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
<html><head>
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <link rel="icon" href="/favicon.ico">
</head></html>
''',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com/page',
        client: client,
      );

      expect(result, 'https://example.com/apple-touch-icon.png');
    });

    test('apple-touch-icon 없으면 rel="icon" 반환', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
<html><head>
  <link rel="icon" href="/favicon-32.png">
</head></html>
''',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, 'https://example.com/favicon-32.png');
    });

    test('rel="shortcut icon" 도 rel="icon" 과 동일하게 인식', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
<html><head>
  <link rel="shortcut icon" href="/favicon.ico">
</head></html>
''',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, 'https://example.com/favicon.ico');
    });

    test('HTML에 아이콘 힌트 전혀 없으면 /favicon.ico 로 폴백', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>no icon</title></head></html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com/path',
        client: client,
      );

      expect(result, 'https://example.com/favicon.ico');
    });

    test('apple-touch-icon 이 절대 URL이면 그대로 반환', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
<html><head>
  <link rel="apple-touch-icon" href="https://cdn.example.com/icon.png">
</head></html>
''',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, 'https://cdn.example.com/icon.png');
    });

    test('apple-touch-icon 이 protocol-relative URL 이면 scheme 붙여서 반환',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
<html><head>
  <link rel="apple-touch-icon" href="//cdn.example.com/icon.png">
</head></html>
''',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, 'https://cdn.example.com/icon.png');
    });

    test('여러 apple-touch-icon 중 첫 번째를 선택', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
<html><head>
  <link rel="apple-touch-icon" sizes="180x180" href="/icon-180.png">
  <link rel="apple-touch-icon" sizes="120x120" href="/icon-120.png">
</head></html>
''',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, 'https://example.com/icon-180.png');
    });

    test('잘못된 URL 이면 null 반환', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('', 200);
      });

      final result = await FaviconLoader.fetch(
        'not a url',
        client: client,
      );

      expect(result, isNull);
      expect(calls, 0);
    });

    test('HTTP 요청 실패시 null 반환', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection refused');
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, isNull);
    });

    test('HTTP 5xx 응답이면 null 반환', () async {
      final client = MockClient((request) async {
        return http.Response('', 500);
      });

      final result = await FaviconLoader.fetch(
        'https://example.com',
        client: client,
      );

      expect(result, isNull);
    });

    test('non-HTML 응답이어도 /favicon.ico 로 폴백', () async {
      // 200 OK 지만 JSON 같은 응답을 받아도 도메인 루트 favicon.ico는 시도
      final client = MockClient((request) async {
        return http.Response(
          '{"error": "not html"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await FaviconLoader.fetch(
        'https://example.com/api/x',
        client: client,
      );

      expect(result, 'https://example.com/favicon.ico');
    });
  });
}
