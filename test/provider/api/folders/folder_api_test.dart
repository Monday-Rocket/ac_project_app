import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../mock_client_generator.dart';

void main() {
  group('get My Folder Api Test', () {
    final apiExpected = ApiResult(
      status: 0,
      data: [
        Folder(
          visible: false,
          name: 'unclassified',
          links: 2,
        ),
        Folder(
          id: 2,
          thumbnail: '01',
          visible: true,
          name: '폴더명',
          links: 2,
          time: '2023-05-15T10:30:00.861975',
        ),
      ],
    );

    test('getMyFolders success test', () async {
      final mockClient = getMockClient(apiExpected, '/folders');
      final api = getFolderApi(mockClient);

      final result = await api.getMyFolders();

      final expected = [
        Folder(
          visible: false,
          name: '미분류',
          links: 2,
        ),
        Folder(
          id: 2,
          thumbnail: '01',
          visible: true,
          name: '폴더명',
          links: 2,
          time: '2023-05-15T10:30:00.861975',
        ),
      ];

      result.when(
        success: (actual) => expect(actual, expected),
        error: fail,
      );
    });

    test('미분류 없는 내 폴더 조회 success test', () async {
      final mockClient = getMockClient(apiExpected, '/folders');
      final api = getFolderApi(mockClient);

      final result = await api.getMyFoldersWithoutUnclassified();

      final expected = [
        Folder(
          id: 2,
          thumbnail: '01',
          visible: true,
          name: '폴더명',
          links: 2,
          time: '2023-05-15T10:30:00.861975',
        ),
      ];

      result.when(
        success: (actual) => expect(actual, expected),
        error: fail,
      );
    });
  });

  test('get others Folder Success Test', () async {
    const userId = 1234;

    final apiExpected = ApiResult(
      status: 0,
      data: [
        Folder(
          id: 1,
          thumbnail: '01',
          visible: true,
          name: '폴더명1',
          links: 2,
          time: '2023-05-15T10:30:00.861975',
        ),
        Folder(
          id: 2,
          thumbnail: '01',
          visible: true,
          name: '폴더명2',
          links: 2,
          time: '2023-05-16T10:30:00.861975',
        ),
      ],
    );

    final mockClient = getMockClient(apiExpected, '/users/$userId/folders');
    final api = getFolderApi(mockClient);

    final result = await api.getOthersFolders(userId);

    result.when(
      success: (actual) => expect(actual, apiExpected.data),
      error: fail,
    );
  });

  test('folder add success test', () async {
    final apiExpected = ApiResult(status: 0);

    final mockClient = getMockClient(apiExpected, '/folders');
    final api = getFolderApi(mockClient);

    final result = await api.add(Folder(name: 'test'));

    expect(result, true);
  });

  // TODO bulkSave 테스트 코드 작성하기
}

FolderApi getFolderApi(MockClient mockClient) {
  return FolderApi(
    client: CustomClient(
      client: mockClient,
      auth: MockFirebaseAuth(
        mockUser: MockUser(
          isAnonymous: true,
        ),
      ),
    ),
  );
}
