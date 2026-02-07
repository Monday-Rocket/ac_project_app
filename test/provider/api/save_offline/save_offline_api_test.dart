import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/save_offline/save_offline_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../mock_client_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveOfflineApi Tests', () {
    test('getSaveOfflineHistory returns true when already completed', () async {
      final apiExpected = ApiResult(status: 0, data: true);
      final mockClient = getMockClient(apiExpected, '/save-offline');
      final api = getSaveOfflineApi(mockClient);

      final result = await api.getSaveOfflineHistory();

      result.when(
        success: (data) => expect(data, true),
        error: fail,
      );
    });

    test('getSaveOfflineHistory returns false when not completed', () async {
      final apiExpected = ApiResult(status: 0, data: false);
      final mockClient = getMockClient(apiExpected, '/save-offline');
      final api = getSaveOfflineApi(mockClient);

      final result = await api.getSaveOfflineHistory();

      result.when(
        success: (data) => expect(data, false),
        error: fail,
      );
    });

    test('completeSaveOffline returns true on success', () async {
      final apiExpected = ApiResult(status: 0);
      final mockClient = getMockClient(apiExpected, '/save-offline');
      final api = getSaveOfflineApi(mockClient);

      final result = await api.completeSaveOffline();

      expect(result, true);
    });

    test('completeSaveOffline returns false on error', () async {
      final apiExpected = ApiResult(status: 0);
      final mockClient = getMockClient(
        apiExpected,
        '/save-offline',
        hasError: true,
      );
      final api = getSaveOfflineApi(mockClient);

      final result = await api.completeSaveOffline();

      expect(result, false);
    });
  });
}

SaveOfflineApi getSaveOfflineApi(MockClient mockClient) {
  return SaveOfflineApi(
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
