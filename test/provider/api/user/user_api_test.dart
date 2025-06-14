import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart' as user;
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

import '../mock_client_generator.dart';

class MockMethodChannel extends Mock implements MethodChannel {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('로그인 Api Test', () {
    test('신규 유저 로그인 Api Test', () async {
      final expected = ApiResult(
        status: 0,
        data: const user.User(id: 0, is_new: true),
      );

      final mockClient = getMockClient(expected, '/users');
      final api = getUserApi(mockClient);

      final result = await api.postUsers();

      result.when(
        success: (actual) => expect(actual, expected.data),
        error: fail,
      );
    });

    test('기존 유저 로그인 Api Test', () async {
      final expected = ApiResult(
        status: 0,
        data: const user.User(id: 0, is_new: false),
      );

      final mockClient = getMockClient(expected, '/users');
      final api = getUserApi(mockClient);

      final result = await api.postUsers();

      result.when(
        success: (actual) => expect(actual, expected.data),
        error: fail,
      );
    });
  });

  test('가입 정보 입력 API', () async {
    final expected = ApiResult(
      status: 0,
      data: DetailUser(
        id: 0,
        nickname: '테스트',
        profile_img: '01', // 처음 기본 프로필 이미지는 01번
      ),
    );

    final mockClient = getMockClient(expected, '/users/me');
    final api = getUserApi(mockClient);

    final result = await api.patchUsers(nickname: '테스트', jobGroupId: 1);

    result.when(
      success: (actual) => expect(actual, expected.data),
      error: fail,
    );
  });

  test('프로필 정보 조회 API', () async {
    final expected = ApiResult(
      status: 0,
      data: DetailUser(
        id: 0,
        nickname: '테스트',
        profile_img: '01', // 처음 기본 프로필 이미지는 01번
      ),
    );

    final mockClient = getMockClient(expected, '/users/me');
    final api = getUserApi(mockClient);

    final result = await api.getUsers();

    result.when(
      success: (actual) => expect(actual, expected.data),
      error: fail,
    );
  });

  group('닉네임 중복 확인 API', () {
    test('닉네임 중복일 때 테스트', () async {
      final expected = ApiResult(
        status: 0,
        data: false,
      );
      const duplicatedNickname = '등록된닉네임';

      final mockClient = getMockClient(expected, '/users?nickname=$duplicatedNickname');
      final api = getUserApi(mockClient);

      final actual = await api.checkDuplicatedNickname(duplicatedNickname);

      expect(actual, expected.data);
    });

    test('닉네임 중복이 아닐 때 테스트', () async {
      final expected = ApiResult(
        status: 0,
        data: true,
      );
      const nickname = '첫닉네임';

      final mockClient = getMockClient(expected, '/users?nickname=$nickname', hasError: true);
      final api = getUserApi(mockClient);

      final actual = await api.checkDuplicatedNickname(nickname);

      expect(actual, expected.data);
    });
  });
}

UserApi getUserApi(MockClient mockClient) {
  return UserApi(
    CustomClient(
      client: mockClient,
      auth: MockFirebaseAuth(
        mockUser: MockUser(
          isAnonymous: true,
        ),
      ),
    ),
  );
}
