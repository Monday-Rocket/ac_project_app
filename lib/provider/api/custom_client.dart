// ignore_for_file: strict_raw_type

import 'dart:convert';

import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class CustomClient extends http.BaseClient {
  static const baseUrl =
      'http://ac-project-api.ap-northeast-2.elasticbeanstalk.com';
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

    request.headers['Content-Type'] = 'application/json';
    request.headers['x-auth-token'] = idToken ?? 'test-token';
    return _inner.send(request);
  }

  Future<Result<dynamic>> getUri(
    String uri, {
    Map<String, String>? headers,
  }) async {
    final finalUrl = baseUrl + uri;
    Log.i('GET: $finalUrl');
    return _makeResult(
      () async => super.get(
        Uri.parse(finalUrl),
        headers: headers,
      ),
    );
  }

  Future<Result<dynamic>> postUri(
    String uri, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final finalUrl = baseUrl + uri;
    Log.i('POST: $finalUrl');
    return _makeResult(
      () async => super.post(
        Uri.parse(finalUrl),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Future<Result<dynamic>> putUri(
    String uri, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final finalUrl = baseUrl + uri;
    Log.i('PUT: $finalUrl');
    return _makeResult(
      () async => super.put(
        Uri.parse(finalUrl),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Future<Result<dynamic>> patchUri(
    String uri, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final finalUrl = baseUrl + uri;
    Log.i('PATCH: $finalUrl');
    return _makeResult(
      () async => super.patch(
        Uri.parse(finalUrl),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Future<Result<dynamic>> deleteUri(
    String uri, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) async {
    final finalUrl = baseUrl + uri;
    Log.i(finalUrl);
    return _makeResult(
      () async => super.delete(
        Uri.parse(finalUrl),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Future<Result> _makeResult(Future<Response> Function() callback) async {
    try {
      final response = await callback.call();

      if (response.statusCode == 200) {
        final apiResult = ApiResult.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
        // 결과 출력
        Log.i(apiResult.toJson());
        if (apiResult.error == null && apiResult.status == 0) {
          return Result.success(apiResult.data);
        } else {
          Log.e(apiResult.error!.message);
          return Result.error('${apiResult.status}');
        }
      }
      final errorMessage = 'Network Error: ${response.statusCode}';
      Log.e(errorMessage);
      return Result.error(errorMessage);
    } catch (e) {
      return const Result.error('통신 에러');
    }
  }

  String? makeBody(dynamic body) {
    String? realBody;
    if (body != null && body is Map<String, dynamic>) {
      realBody = jsonEncode(body);
    } else if (body != null && body is List) {
      realBody = stringifyMessage(body);
    } else {
      realBody = null;
    }
    Log.i(realBody);
    return realBody;
  }
}
