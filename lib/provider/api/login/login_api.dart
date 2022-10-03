import 'dart:convert';

import 'package:ac_project_app/models/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class LoginApi {
  final client = CustomClient();

  Future<ApiResult> createUser() async {

    final result = await client.postUri('/users');
    final apiResult = ApiResult.fromJson(jsonDecode(result.body));
    return apiResult;
  }
}
