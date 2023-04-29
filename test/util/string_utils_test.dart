import 'dart:convert';

import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('hasHttpImageUrl() test', () {
    test('link url이 http로 시작할 때만 true이다', () {
      final link1 = Link();
      var actual = hasHttpImageUrl(link1);
      expect(actual, false);

      final link2 = Link(image: '');
      actual = hasHttpImageUrl(link2);
      expect(actual, false);

      final link3 = Link(image: '_____https://');
      actual = hasHttpImageUrl(link3);
      expect(actual, false);

      final link4 = Link(image: 'http://');
      actual = hasHttpImageUrl(link4);
      expect(actual, true);

      final link5 = Link(image: 'https://');
      actual = hasHttpImageUrl(link5);
      expect(actual, true);
    });
  });

  group('UTC 시간을 일정 시간 간격 별로 변환하는 makeLinkTimeString() 테스트', () {
    // 현재 위치의 UTC 시간 간격 계산
    final inMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final hourGap = inMinutes ~/ 60;
    final minuteGap = inMinutes % 60;

    // 기준 시간은 2023년 4월 29일로 한다.
    const utcDateTime = '2023-04-29T00:00:00';
    final testTime = DateTime(2023, 4, 29, hourGap, minuteGap).toUtc();

    test('59초 전에 작성한 글의 표시 시간은 "방금 전" 이다', () {
      const seconds = Duration(seconds: 59);
      final utcTimeAfter59Seconds = testTime.add(seconds);

      final actual = makeLinkTimeString(utcDateTime, utcTimeAfter59Seconds);

      expect(actual, '방금 전');
    });

    test('30분 전에 작성한 글의 표시 시간은 "30분 전" 이다', () {
      const minutes = Duration(minutes: 30);
      final utcTimeAfter30Minutes = testTime.add(minutes);

      final actual = makeLinkTimeString(utcDateTime, utcTimeAfter30Minutes);

      expect(actual, '30분 전');
    });

    test('13시간 전에 작성한 글의 표시 시간은 "13시간 전" 이다', () {
      const hours = Duration(hours: 13);
      final utcTimeAfter13Hours = testTime.add(hours);

      final actual = makeLinkTimeString(utcDateTime, utcTimeAfter13Hours);

      expect(actual, '13시간 전');
    });

    test('6일 전에 작성한 글의 표시 시간은 "6일 전" 이다', () {
      const hours = Duration(days: 6);
      final utcTimeAfter6Days = testTime.add(hours);

      final actual = makeLinkTimeString(utcDateTime, utcTimeAfter6Days);

      expect(actual, '6일 전');
    });

    test('7일 전에 작성한 글의 표시 시간은 "7일 전"이 아니라 작성된 글의 날짜를 "yyyy/MM/dd"형태로 반환한다', () {
      const hours = Duration(days: 7);
      final utcTimeAfter7Days = testTime.add(hours);

      final actual = makeLinkTimeString(utcDateTime, utcTimeAfter7Days);
      expect(actual != '7일전', true);

      final matcher = DateFormat('yyyy/MM/dd').format(testTime);
      expect(actual, matcher);
    });

    test('잘못된 형태의 시간이 입력된다면 표시 시간은 "알 수 없음" 이다', () {
      final actual = makeLinkTimeString('unknown', testTime);

      expect(actual, '알 수 없음');
    });

    test('작성된 글보다 과거의 시간에서 표시 시간을 확인하면 빈 문자열로 반환한다', () {
      const hours = Duration(hours: 3);
      final utcTimeBefore3Hours = testTime.subtract(hours);

      final actual = makeLinkTimeString(utcDateTime, utcTimeBefore3Hours);

      expect(actual, '');
    });
  });

  test('getCurrentTime 함수는 현재 시간을 yyyy-MM-ddThh:mm:ssZ 형태의 문자열로 반환한다', () {
    // 기준 시간은 2023년 4월 29일 13시 26분 39로 한다.
    // 현재 위치의 UTC 시간 간격 계산
    final testCurrentTime = DateTime(2023, 4, 29, 13, 26, 39);

    final actual = getCurrentTime(testCurrentTime);

    expect(actual, '2023-04-29T13:26:39Z');
  });

  group('링크 제목 문자열 30자 이하로만 표현하도록 자르는 함수 테스트', () {
    const textThatMoreThan30Chars = '0123456789'
        '0123456789'
        '0123456789'
        '30자가 넘는 구간';

    test('30자가 넘는 String을 변환했을 때 30자까지만 표현', () {
      final result = getShortTitle(textThatMoreThan30Chars);

      expect(
          result,
          '0123456789'
          '0123456789'
          '0123456789');
    });

    test('30자가 넘고 base64 인코딩 된 String을 변환했을 때 30자까지만 표현', () {
      final test = base64Encode(utf8.encode(textThatMoreThan30Chars));

      final result = getShortTitleFromBase64String(test);

      expect(
          result,
          '0123456789'
          '0123456789'
          '0123456789');
    });

    const textThatLessThan30Chars = '0123456789';

    test('30자가 넘지 않는 String을 변환했을 때 그대로 리턴', () {
      final actual1 = getShortTitle(textThatLessThan30Chars);
      expect(actual1, textThatLessThan30Chars);

      final actual2 = getShortTitleFromBase64String(
        base64Encode(utf8.encode(textThatLessThan30Chars)),
      );

      expect(actual2, textThatLessThan30Chars);
    });
  });
}
