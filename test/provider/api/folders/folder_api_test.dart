import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../../../test_strings.dart';
import '../mock_client_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('get My Folder Api Test', () {
    final apiExpected = ApiResult(
      status: 0,
      data: [
        const Folder(
          visible: false,
          name: 'unclassified',
          links: 2,
        ),
        const Folder(
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
        const Folder(
          visible: false,
          name: '미분류',
          links: 2,
        ),
        const Folder(
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
        const Folder(
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
        const Folder(
          id: 1,
          thumbnail: '01',
          visible: true,
          name: '폴더명1',
          links: 2,
          time: '2023-05-15T10:30:00.861975',
        ),
        const Folder(
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

    final result = await api.add(const Folder(name: 'test'));

    expect(result, true);
  });

  test('bulk save success test', () async {
    const channel = MethodChannel('share_data_provider');
    // channel.setMockMethodCallHandler((call) async {});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'getNewLinks') {
          return {
            getNewLinksKey: getNewLinksValue,
          };
        } else if (call.method == 'getNewFolders') {
          return getNewFoldersResult;
        }
        return null;
      },
    );

    final apiExpected = ApiResult(status: 0);

    final mockClient = getMockClient(apiExpected, '/bulk');
    final api = getFolderApi(mockClient);
    final result = await api.bulkSave();

    expect(result, true);
  });

  test('delete folder success test', () async {
    final apiExpected = ApiResult(status: 0);

    const folder = Folder(
      id: 1,
      thumbnail: '01',
      visible: true,
      name: '폴더명1',
      links: 2,
      time: '2023-05-15T10:30:00.861975',
    );

    final mockClient = getMockClient(apiExpected, '/folders/${folder.id}');
    final api = getFolderApi(mockClient);
    final result = await api.deleteFolder(folder);

    expect(result, true);
  });

  test('patch folder name success test', () async {
    final apiExpected = ApiResult(status: 0);

    const folder = Folder(
      id: 1,
      thumbnail: '01',
      visible: true,
      name: '폴더명1',
      links: 2,
      time: '2023-05-15T10:30:00.861975',
    );

    final mockClient = getMockClient(apiExpected, '/folders/${folder.id}');
    final api = getFolderApi(mockClient);
    final result = await api.patchFolder(folder.id!, {'name': '바꿀 폴더명'});

    expect(result, true);
  });

  test('change folder visibility success test', () async {
    final apiExpected = ApiResult(status: 0);

    const folder = Folder(
      id: 1,
      thumbnail: '01',
      visible: true,
      name: '폴더명1',
      links: 2,
      time: '2023-05-15T10:30:00.861975',
    );

    final mockClient = getMockClient(apiExpected, '/folders/${folder.id}');
    final api = getFolderApi(mockClient);
    final result = await api.changeVisible(folder);

    expect(result, true);
  });
}

FolderApi getFolderApi(MockClient mockClient) {
  return FolderApi(
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
