import 'dart:convert';

import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class LoginApi {
  final client = CustomClient();

  Future<ApiResult> postUsers() async {
    final result = await client.postUri('/users');
    return ApiResult.fromJson(jsonDecode(result.body) as Map<String, dynamic>);
  }
}
