import 'package:ac_project_app/models/user/patch_result.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final userApi = UserApi();
  test('create user test', () async {
    final result = await userApi.postUsers();
    result.when(
      success: (data) {
        expect(data, User('1'));
      },
      error: fail,
    );
  });

  test('update user test', () async {
    const id = '1';
    const nickname = 'test';
    const jobGroupId = '1';

    final result = await userApi.patchUsers(id, nickname, jobGroupId);

    result.when(
      success: (data) {
        expect(
          data,
          PatchResult(
            id: '1',
            nickname: 'test',
            jobGroup: JobGroup(id: 1, name: '소프트웨어 엔지니어'),
          ),
        );
      },
      error: fail,
    );
  });
}
