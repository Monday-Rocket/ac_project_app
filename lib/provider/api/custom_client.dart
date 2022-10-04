// ignore_for_file: strict_raw_type

import 'dart:convert';

import 'package:ac_project_app/const/token.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:http/http.dart' as http;

class CustomClient extends http.BaseClient {
  static const baseUrl =
      'https://fe9665db-ca48-4591-8a53-683a48b40f40.mock.pstmn.io';
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['x-auth-token'] = globalToken ?? '1234';
    return _inner.send(request);
  }

  Future<Result<Map<String, dynamic>>> getUri(
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

  Future<Result<Map<String, dynamic>>> postUri(
    String uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _makeResult(
      await super.post(
        Uri.parse(baseUrl + uri),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }

  Future<Result<Map<String, dynamic>>> putUri(
    String uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _makeResult(
      await super.put(
        Uri.parse(baseUrl + uri),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }

  Future<Result> patchUri(
    String uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _makeResult(
      await super.patch(
        Uri.parse(baseUrl + uri),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }

  Result<Map<String, dynamic>> _makeResult(http.Response response) {
    if (response.statusCode == 200) {
      final apiResult = ApiResult<Map<String, dynamic>>.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (apiResult.error == null) {
        return Result.success(apiResult.data);
      } else {
        return Result.error(apiResult.error!.message);
      }
    }
    return const Result.error('Network Error');
  }
}
