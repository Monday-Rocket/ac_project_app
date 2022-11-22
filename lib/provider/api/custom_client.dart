// ignore_for_file: strict_raw_type

import 'dart:convert';

import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/stringfy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CustomClient extends http.BaseClient {
  static const baseUrl =
      'http://ac-project-api.ap-northeast-2.elasticbeanstalk.com';
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

    await Clipboard.setData(ClipboardData(text: idToken));

    request.headers['Content-Type'] = 'application/json';
    request.headers['x-auth-token'] = idToken ?? 'test-token';
    return _inner.send(request);
  }

  Future<Result<dynamic>> getUri(
    String uri, {
    Map<String, String>? headers,
  }) async {
    final finalUrl = baseUrl + uri;
    Log.i(finalUrl);
    return _makeResult(
      await super.get(
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
    Log.i(finalUrl);
    return _makeResult(
      await super.post(
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
    Log.i(finalUrl);
    return _makeResult(
      await super.put(
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
    Log.i(finalUrl);
    return _makeResult(
      await super.patch(
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
      await super.delete(
        Uri.parse(finalUrl),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Result<dynamic> _makeResult(http.Response response) {
    if (response.statusCode == 200) {
      final apiResult = ApiResult<dynamic>.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
      // 결과 출력
      Log.i(apiResult.toJson());
      if (apiResult.error == null) {
        return Result.success(apiResult.data);
      } else {
        Log.e(apiResult.error!.message);
        return Result.error(apiResult.error!.message);
      }
    }
    final errorMessage = 'Network Error: ${response.statusCode}';
    Log.e(errorMessage);
    return Result.error(errorMessage);
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
