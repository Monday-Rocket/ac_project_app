import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/provider/sync/pro_mutate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('proMutate - 성공 경로', () {
    test('remote 성공 → local 호출 → 결과 반환', () async {
      final localCalls = <int>[];
      final result = await proMutate<int>(
        remote: () async => 42,
        local: (v) async {
          localCalls.add(v);
        },
      );
      expect(result, 42);
      expect(localCalls, [42]);
    });

    test('local 이 null 이어도 remote 결과 반환', () async {
      final result = await proMutate<String>(
        remote: () async => 'ok',
      );
      expect(result, 'ok');
    });
  });

  group('proMutate - 오프라인 경로', () {
    test('SocketException → ProMutateOfflineException + local 호출 안 됨', () async {
      var localCalled = false;
      await expectLater(
        proMutate<void>(
          remote: () async => throw const SocketException('no network'),
          local: (_) async {
            localCalled = true;
          },
        ),
        throwsA(isA<ProMutateOfflineException>()),
      );
      expect(localCalled, isFalse);
    });

    test('TimeoutException → ProMutateOfflineException', () async {
      await expectLater(
        proMutate<void>(
          remote: () async => throw TimeoutException('slow'),
        ),
        throwsA(isA<ProMutateOfflineException>()),
      );
    });

    test('http.ClientException → ProMutateOfflineException', () async {
      await expectLater(
        proMutate<void>(
          remote: () async => throw http.ClientException('bad dns'),
        ),
        throwsA(isA<ProMutateOfflineException>()),
      );
    });

    test('HttpException → ProMutateOfflineException', () async {
      await expectLater(
        proMutate<void>(
          remote: () async => throw const HttpException('connection closed'),
        ),
        throwsA(isA<ProMutateOfflineException>()),
      );
    });
  });

  group('proMutate - 기타 예외는 상향', () {
    test('StateError 는 원본 그대로 던져짐', () async {
      await expectLater(
        proMutate<void>(
          remote: () async => throw StateError('server 500'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('isOfflineException', () {
    test('오프라인 범주 예외 판정', () {
      expect(isOfflineException(const SocketException('x')), isTrue);
      expect(isOfflineException(TimeoutException('x')), isTrue);
      expect(isOfflineException(http.ClientException('x')), isTrue);
      expect(isOfflineException(const HttpException('x')), isTrue);
      expect(isOfflineException(ProMutateOfflineException('x')), isTrue);
    });

    test('그 외 예외는 false', () {
      expect(isOfflineException(StateError('x')), isFalse);
      expect(isOfflineException(ArgumentError('x')), isFalse);
    });
  });
}
