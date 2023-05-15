import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../mock_client_generator.dart';

void main() {
  group('Group Api Test', () {
    test('getMyFolders success test', () async {
      final expected = ApiResult(
        status: 0,
        data: [
          Folder(
            id: 1,
            thumbnail: '01',
            visible: true,
            name: '폴더명',
            links: 2,
            time: '2023-05-15T10:30:00.861975',
          )
        ],
      );

      final mockClient = getMockClient(expected, '/folders');
      final api = getFolderApi(mockClient);

      final result = await api.getMyFolders();

      result.when(
        success: (actual) => expect(actual, expected.data),
        error: fail,
      );
    });
  });
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
