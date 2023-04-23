import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  test('ProfileApi ChangeApi Success Test', () async {
    // Given: 변경하려는 프로필 이미지 번호는 2번
    const targetProfileImageNumber = '02';
    final expectedResult = ApiResult(
      status: 0,
      data: DetailUser(
        profile_img: targetProfileImageNumber,
      ),
    );

    // When 1: ProfileApi의 MockClient 설정하고
    final mockClient = MockClient((request) async {
      if (request.url.toString() == '$baseUrl/users/me') {
        return http.Response(
          jsonEncode(expectedResult),
          200,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'
          },
        );
      }
      return http.Response('error', 404);
    });

    final profileApi = ProfileApi(
      client: CustomClient(
        client: mockClient,
        auth: MockFirebaseAuth(),
      ),
    );

    // When 2: ProfileApi의 changeImage() 실행했을 때,
    final result = await profileApi.changeImage(
      profileImg: targetProfileImageNumber,
    );

    // Then: 예상했던 결과와 동일하게 나오는지 확인한다.
    result.when(
      success: (actual) => expect(actual, expectedResult.data),
      error: fail,
    );
  });
}
