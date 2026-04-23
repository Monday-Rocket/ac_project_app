import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/util/logger.dart';
import 'package:http/http.dart' as http;

/// Pro CRUD 원격 쓰기를 감싸는 통합 래퍼.
///
/// 정책 (SYNC_MODEL_V2 §2.2):
/// - Pro 상태에서 모든 mutation 은 원격 먼저 → 성공 후 로컬 반영.
/// - 오프라인/네트워크 실패 시 [ProMutateOfflineException] 을 던져 호출부가 롤백.
/// - 인증 실패 시 [ProMutateAuthException].
/// - 그 외 서버 오류는 원본 예외를 그대로 상향.
///
/// fire-and-forget / dirty flag 패턴은 v2 에서 폐기한다. 실패는 삼키지 않는다.
class ProMutateOfflineException implements Exception {
  ProMutateOfflineException(this.cause);
  final Object cause;
  @override
  String toString() => 'ProMutateOfflineException: $cause';
}

class ProMutateAuthException implements Exception {
  ProMutateAuthException(this.message);
  final String message;
  @override
  String toString() => 'ProMutateAuthException: $message';
}

/// 원격 호출 [remote] → 성공 시 [local] 을 실행해 결과 반환.
///
/// [remote] 가 네트워크 오류로 실패하면 [local] 은 실행되지 않고
/// [ProMutateOfflineException] 이 상향된다.
Future<T> proMutate<T>({
  required Future<T> Function() remote,
  Future<void> Function(T remoteResult)? local,
}) async {
  T result;
  try {
    result = await remote();
  } on SocketException catch (e) {
    Log.e('proMutate offline (SocketException): $e');
    throw ProMutateOfflineException(e);
  } on TimeoutException catch (e) {
    Log.e('proMutate offline (TimeoutException): $e');
    throw ProMutateOfflineException(e);
  } on http.ClientException catch (e) {
    Log.e('proMutate offline (ClientException): $e');
    throw ProMutateOfflineException(e);
  } on HttpException catch (e) {
    Log.e('proMutate offline (HttpException): $e');
    throw ProMutateOfflineException(e);
  }

  if (local != null) {
    await local(result);
  }
  return result;
}

/// 원격 예외가 네트워크/오프라인 범주인지 판정 (외부 호출부용).
bool isOfflineException(Object e) {
  return e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException ||
      e is HttpException ||
      e is ProMutateOfflineException;
}
