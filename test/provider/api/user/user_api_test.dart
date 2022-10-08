import 'package:ac_project_app/models/job/topic.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final userApi = UserApi();
  test('최초 유저 생성', () async {
    final result = await userApi.postUsers();
    result.when(
      success: (data) {
        expect(data, const User(id: '1'));
      },
      error: fail,
    );
  });

  test('유저 정보 수정', () async {
    const id = '1';
    const nickname = 'test';
    const jobGroupId = '1';

    final result = await userApi.patchUsers(id, nickname, jobGroupId);

    result.when(
      success: (data) {
        expect(
          data,
          DetailUser(
            id: '1',
            nickname: 'test',
            jobGroup: JobGroup(id: 1, name: '소프트웨어 엔지니어'),
          ),
        );
      },
      error: fail,
    );
  });

  test('유저 조회', () async {
    final result = await userApi.getUsers();
    result.when(
      success: (data) {
        expect(
          data,
          DetailUser(
            id: '1',
            nickname: 'test',
            jobGroup: JobGroup(id: 1, name: '소프트웨어 엔지니어'),
          ),
        );
      },
      error: fail,
    );
  });

  test('get job groups', () async {
    final result = await userApi.getJobGroups();
    return result.when(
      success: (data) {
        expect(data, [
          JobGroup(
            id: 1,
            name: '소프트웨어 엔지니어',
          ),
          JobGroup(
            id: 2,
            name: '기획자',
          ),
          JobGroup(
            id: 3,
            name: '디자이너',
          ),
          JobGroup(
            id: 4,
            name: '데이터 엔지니어',
          ),
        ]);
      },
      error: fail,
    );
  });

  test('get topics', () async {
    final result = await userApi.getTopics();
    return result.when(
      success: (data) {
        expect(data, [
          Topic(
            id: 1,
            name: '개발',
          ),
          Topic(
            id: 2,
            name: '예술',
          ),
          Topic(
            id: 3,
            name: '역사',
          ),
          Topic(
            id: 4,
            name: '디자인',
          ),
          Topic(
            id: 5,
            name: 'PM',
          ),
        ]);
      },
      error: fail,
    );
  });
}
