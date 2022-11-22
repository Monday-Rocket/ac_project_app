// ignore_for_file: strict_raw_type

import 'package:ac_project_app/models/job/topic.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class UserApi {
  final client = CustomClient();

  Future<Result<User>> postUsers() async {
    final result = await client.postUri('/users');
    return result.when(
      success: (data) =>
          Result.success(User.fromJson(data as Map<String, dynamic>)),
      error: Result.error,
    );
  }

  Future<Result<DetailUser>> patchUsers({
    String? nickname,
    int? jobGroupId,
    String? profileImg,
  }) async {
    final result = await client.patchUri(
      '/users',
      body: {
        'nickname': nickname,
        'job_group_id': jobGroupId.toString(),
        'profile_img': profileImg
      },
    );
    return result.when(
      success: (data) => Result.success(DetailUser.fromJson(data)),
      error: Result.error,
    );
  }

  Future<Result<DetailUser>> getUsers() async {
    final result = await client.getUri('/users');
    return result.when(
      success: (data) => Result.success(DetailUser.fromJson(data)),
      error: Result.error,
    );
  }

  Future<Result<List<JobGroup>>> getJobGroups() async {
    final result = await client.getUri('/job-groups');
    return result.when(
      success: (data) => Result.success(
        JobGroup.fromJsonList(data as List<dynamic>),
      ),
      error: Result.error,
    );
  }

  Future<Result<List<Topic>>> getTopics() async {
    final result = await client.getUri('/topics');
    return result.when(
      success: (data) => Result.success(
        Topic.fromJsonList(data as List<dynamic>),
      ),
      error: Result.error,
    );
  }
}
