// ignore_for_file: avoid_print

import 'package:ac_project_app/util/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  group('yyyy-MM-ddThh:mm:ss 형태로 된 시간에서 "월 일, 연도" 형태로 변환하기', () {
    test('2023년 1월 18일을 변환하면 Jan 18, 2023이다', () {
      const date = '2023-01-18T07:23:09';
//
      final actual = getMonthDayYear(date);
      const matcher = 'Jan 18, 2023';

      expect(actual, matcher);
    });

    test('1월부터 12월 까지 영문 월이 제대로 나오는 지 테스트', () {
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      for (var i = 1; i <= 12; i++) {
        final month = i.toString().padLeft(2, '0');
        final date = '2023-$month-01T00:00:00';

        final actual = getMonthDayYear(date).split(' ').first;
        final matcher = monthNames[i-1];

        print(actual);
        expect(actual, matcher);
      }
    });

    test('입력 값이 비어 있다면 결과도 비어 있다', () {
      const date = '';

      final actual = getMonthDayYear(date);
      const matcher = '';

      expect(actual, matcher);
    });
  });
}
