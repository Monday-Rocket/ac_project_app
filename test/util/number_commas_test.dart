import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  group('int 값을 3자릿수 마다 , 찍는 문자열로 변환하는 함수 테스트', () {
    test('1을 변환하면 "1"이다.', () {
      const number = 1;

      final actual = addCommasFrom(number);

      expect(actual, '1');
    });

    test('-1234를 변환하면 음수는 0으로 바꾼다.', () {
      const number = -1234;

      final actual = addCommasFrom(number);

      expect(actual, '0');
    });

    test('1234567890을 변환하면 "1,234,567,890"이다', () {
      const number = 1234567890;

      final actual = addCommasFrom(number);

      expect(actual, '1,234,567,890');
    });

    test('null을 변환하면 ""이다.', () {
      // ignore: unnecessary_cast
      const number = null as int?;

      final actual = addCommasFrom(number);

      expect(actual, '');
    });
  });
}
