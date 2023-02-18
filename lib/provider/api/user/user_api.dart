// ignore_for_file: strict_raw_type

import 'dart:async';

import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/models/job/topic.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/logout.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';

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
  }) async {
    final result = await client.patchUri(
      '/users/me',
      body: {
        'nickname': nickname,
        'job_group_id': jobGroupId.toString(),
        'profile_img': '01',
      },
    );
    return result.when(
      success: (data) => Result.success(DetailUser.fromJson(data)),
      error: Result.error,
    );
  }

  Future<Result<DetailUser>> getUsers() async {
    final result = await client.getUri('/users/me');
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

  Future<bool> deleteUser(BuildContext context) async {
    // 1. 공유패널 데이터 비우기
    unawaited(ShareDataProvider.clearAllData());

    // 2. 데이터 삭제
    // 3. 로그아웃
    final result = await client.deleteUri('/users');
    return result.when(
      success: (_) async => logoutWithoutPush(context),
      error: (_) => false,
    );
  }

  Future<bool> checkDuplicatedNickname(String nickName) async {
    final fullUrl = '$baseUrl/users?nickname=$nickName';
    final result = await client.head(Uri.parse(fullUrl));
    Log.i('HEAD: $fullUrl');

    if (result.statusCode == 404) {
      return true;
    } else if (result.statusCode == 200) {
      Log.i('닉네임 중복');
    }

    return false;
  }
}
