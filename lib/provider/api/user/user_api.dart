// ignore_for_file: strict_raw_type

import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/patch_result.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class UserApi {
  final client = CustomClient();

  Future<Result<User>> postUsers() async {
    final result = await client.postUri('/users');
    return result.when(
      success: (data) => Result.success(User.fromJson(data)),
      error: Result.error,
    );
  }

  Future<Result<PatchResult>> patchUsers(
    String id,
    String nickname,
    String jobGroupId,
  ) async {
    final result = await client.putUri(
      '/users/$id',
      body: {
        'nickname': nickname,
        'jobGroupId': jobGroupId,
      },
    );
    return result.when(
      success: (data) => Result.success(PatchResult.fromJson(data)),
      error: Result.error,
    );
  }
}
