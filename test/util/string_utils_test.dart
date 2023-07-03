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
    final inMinutes = DateTime
        .now()
        .timeZoneOffset
        .inMinutes;
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
    const textThatMoreThan30Chars =
        '0123456789'
        '0123456789'
        '0123456789'
        '30자가 넘는 구간';

    const textThatLessThan30Chars = '0123456789';

    test('30자가 넘는 String을 변환했을 때 30자까지만 표현', () {
      final result = getShortTitle(textThatMoreThan30Chars);

      expect(
          result,
          '0123456789'
              '0123456789'
              '0123456789');
    });

    test('30자가 넘지 않는 String을 변환했을 때 그대로 리턴', () {
      final actual = getShortTitle(textThatLessThan30Chars);
      expect(actual, textThatLessThan30Chars);

      expect(actual, textThatLessThan30Chars);
    });
  });

  group('base64 텍스트를 decode하는 함수 테스트', () {
    const testText = '1234';

    test('정상적으로 base64 인코딩된 텍스트를 decode 하는 테스트', () {
      final encoded = base64Encode(utf8.encode(testText));

      final actual = decodeBase64Text(encoded);

      expect(actual, testText);
    });

    test('비정상적으로 base64 인코딩된 텍스트를 decode 하는 테스트', () {
      const encoded = '비정상적 텍스트';

      final actual = decodeBase64Text(encoded);

      expect(actual, '');
    });
  });

  // isLinkValid 테스트
  group('링크가 유효한지 확인하는 함수 테스트', () {
    test('링크가 유효한 경우', () {
      final actual = isLinkValid('https://url');
      expect(actual, true);
    });

    // case1
    test('링크가 유효하지 않은 경우1', () {
      final actual = isLinkValid('');
      expect(actual, false);
    });

    // case2
    test('링크가 유효하지 않은 경우2', () {
      final actual = isLinkValid('https://');
      expect(actual, false);
    });
  });
}
