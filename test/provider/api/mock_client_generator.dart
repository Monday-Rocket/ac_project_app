import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient getMockClient(
  ApiResult expected,
  String path, {
  bool? hasError,
  int errorCode = 404,
  String errorMessage = 'error',
}) {
  final mockClient = MockClient((request) async {
    final url = Uri.decodeFull(request.url.toString());

    if (hasError ?? false) return http.Response(errorMessage, errorCode);
    if (url == '$baseUrl$path') {
      return http.Response(
        jsonEncode(expected),
        200,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json;charset=utf-8',
        },
      );
    }
    return http.Response(errorMessage, errorCode);
  });
  return mockClient;
}
