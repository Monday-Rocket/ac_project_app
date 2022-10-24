// ignore_for_file: strict_raw_type

import 'dart:convert';

import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CustomClient extends http.BaseClient {
  static const baseUrl =
      'http://ac-project-api.ap-northeast-2.elasticbeanstalk.com/';
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
    return _makeResult(
      await super.get(
        Uri.parse(baseUrl + uri),
        headers: headers,
      ),
    );
  }

  Future<Result<dynamic>> postUri(
    String uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) async {
    return _makeResult(
      await super.post(
        Uri.parse(baseUrl + uri),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Future<Result<dynamic>> putUri(
    String uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) async {
    return _makeResult(
      await super.put(
        Uri.parse(baseUrl + uri),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Future<Result<dynamic>> patchUri(
    String uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) async {
    return _makeResult(
      await super.patch(
        Uri.parse(baseUrl + uri),
        headers: headers,
        body: makeBody(body),
        encoding: encoding,
      ),
    );
  }

  Result<dynamic> _makeResult(http.Response response) {
    if (response.statusCode == 200) {
      final apiResult = ApiResult<dynamic>.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (apiResult.error == null) {
        return Result.success(apiResult.data);
      } else {
        return Result.error(apiResult.error!.message);
      }
    }
    return Result.error('Network Error: ${response.statusCode}');
  }

  String? makeBody(Map<String, dynamic>? body) {
    if (body != null) {
      return jsonEncode(body);
    }
    return null;
  }
}
