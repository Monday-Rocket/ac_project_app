import 'dart:convert';

import 'package:ac_project_app/const/token.dart';
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

  Future<http.Response> getUri(
    String uri, {
    Map<String, String>? headers,
  }) {
    return super.get(
      Uri.parse(baseUrl + uri),
      headers: headers,
    );
  }

  Future<http.Response> postUri(
    String uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.post(
      Uri.parse(baseUrl + uri),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> putUri(
      String uri, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    return super.put(
      Uri.parse(baseUrl + uri),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> patchUri(
      String uri, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    return super.patch(
      Uri.parse(baseUrl + uri),
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }
}
