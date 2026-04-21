import 'package:ac_project_app/util/link_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LinkChecker', () {
    test('empty urls → no calls, empty results', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('', 200);
      });

      final results = await LinkChecker.checkLinks([], client: client);

      expect(results, isEmpty);
      expect(calls, 0);
    });

    test('2xx HEAD → ok=true', () async {
      final client = MockClient((request) async {
        expect(request.method, 'HEAD');
        return http.Response('', 200);
      });

      final results = await LinkChecker.checkLinks(
        ['https://example.com'],
        client: client,
      );

      expect(results, hasLength(1));
      expect(results[0].ok, isTrue);
      expect(results[0].status, 200);
    });

    test('HEAD 405 → retries with GET (fallback)', () async {
      final methodSeen = <String>[];
      final client = MockClient((request) async {
        methodSeen.add(request.method);
        if (request.method == 'HEAD') {
          return http.Response('', 405);
        }
        return http.Response('body', 200);
      });

      final results = await LinkChecker.checkLinks(
        ['https://example.com'],
        client: client,
      );

      expect(methodSeen, ['HEAD', 'GET']);
      expect(results[0].ok, isTrue);
      expect(results[0].status, 200);
    });

    test('HEAD 403 → retries with GET', () async {
      final client = MockClient((request) async {
        if (request.method == 'HEAD') {
          return http.Response('', 403);
        }
        return http.Response('ok', 200);
      });

      final results = await LinkChecker.checkLinks(
        ['https://example.com'],
        client: client,
      );

      expect(results[0].ok, isTrue);
    });

    test('HEAD 404 → no GET fallback (genuinely broken)', () async {
      var getCalled = false;
      final client = MockClient((request) async {
        if (request.method == 'GET') getCalled = true;
        return http.Response('', 404);
      });

      final results = await LinkChecker.checkLinks(
        ['https://example.com'],
        client: client,
      );

      expect(getCalled, isFalse);
      expect(results[0].ok, isFalse);
      expect(results[0].status, 404);
    });

    test('HEAD throws → retries with GET', () async {
      var getCalled = false;
      final client = MockClient((request) async {
        if (request.method == 'HEAD') {
          throw http.ClientException('connection reset');
        }
        getCalled = true;
        return http.Response('ok', 200);
      });

      final results = await LinkChecker.checkLinks(
        ['https://example.com'],
        client: client,
      );

      expect(getCalled, isTrue);
      expect(results[0].ok, isTrue);
    });

    test('invalid URL → ok=false without HTTP call', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('', 200);
      });

      final results = await LinkChecker.checkLinks(
        ['not a url'],
        client: client,
      );

      expect(calls, 0);
      expect(results[0].ok, isFalse);
      expect(results[0].status, isNull);
    });

    test('progress callback fires per URL (1-step granularity)', () async {
      final client = MockClient((_) async => http.Response('', 200));
      final progress = <int>[];

      await LinkChecker.checkLinks(
        List.generate(12, (i) => 'https://example.com/$i'),
        client: client,
        onProgress: (checked, total) => progress.add(checked),
      );

      expect(progress, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    });

    test('cancelToken: 첫 배치 후 cancel → 남은 배치 건너뜀', () async {
      var calls = 0;
      final token = LinkCheckCancelToken();
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 200);
      });

      final results = await LinkChecker.checkLinks(
        List.generate(25, (i) => 'https://example.com/$i'),
        client: client,
        cancelToken: token,
        onProgress: (checked, total) {
          if (checked >= 10) token.cancel();
        },
      );

      // 첫 10개만 요청됨 (이후 배치는 skip)
      expect(calls, 10);
      // 수집된 결과는 완료된 10건만
      expect(results, hasLength(10));
    });

    test('cancelToken: 시작 전 cancel → 즉시 빈 결과', () async {
      final token = LinkCheckCancelToken()..cancel();
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 200);
      });

      final results = await LinkChecker.checkLinks(
        List.generate(5, (i) => 'https://example.com/$i'),
        client: client,
        cancelToken: token,
      );

      expect(calls, 0);
      expect(results, isEmpty);
    });
  });
}
