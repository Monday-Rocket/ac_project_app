import 'package:ac_project_app/util/url_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // test UrlLoader
  group('UrlLoader test', () {
    test('UrlLoader 정상 test', () async {
      const url = 'https://zdnet.co.kr/view/?no=20131119174125';
      final actual = await UrlLoader.loadData(url);
      expect(actual, isNotNull);
    });

    // 비정상 test
    test('UrlLoader 비정상 test', () async {
      try {
        const url = 'https://error';
        await UrlLoader.loadData(url);
        fail('UrlLoader.loadData() should throw an exception');
      } catch (e) {
        expect(e, isException);
      }
    });
  });
}
