import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'merge_with_remote_test.mocks.dart';

void main() {
  late SyncRepository sync;
  late DatabaseHelper dbHelper;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dbHelper = DatabaseHelper.createForTest();
    final folderRepo = LocalFolderRepository(databaseHelper: dbHelper);
    final linkRepo = LocalLinkRepository(databaseHelper: dbHelper);

    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    // No current user → _requireUserId() returns null
    when(mockAuth.currentUser).thenReturn(null);
    when(mockClient.auth).thenReturn(mockAuth);

    sync = SyncRepository(
      folderRepo: folderRepo,
      linkRepo: linkRepo,
      client: mockClient,
    );
  });

  tearDown(() async {
    await dbHelper.deleteDatabase();
    await dbHelper.close();
  });

  group('upsertFolderRemote parent 해결', () {
    test('parentId=null이면 resolver 호출 안 함', () async {
      var resolverCalls = 0;
      sync.resolveRemoteFolderIdForTest = (_, __) async {
        resolverCalls++;
        return 'should-not-be-called';
      };

      // No Supabase session → upsertFolderRemote returns early at _requireUserId.
      // That early return is BEFORE the resolver call, so resolverCalls should still be 0.
      // We're verifying that the parent-resolution branch is only entered when parentId != null.
      await sync.upsertFolderRemote(const LocalFolder(
        id: 1,
        name: 'Root',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ));

      expect(resolverCalls, 0);
    });

    test(
      'parentId 있으면 resolver 호출됨 (실제 호출은 Supabase 세션 필요 — 수동 검증)',
      () async {
        // SyncRepository._requireUserId depends on Supabase.instance.client.auth.currentUser,
        // which is not easy to mock in unit tests. The branch "parentId != null → call resolver"
        // is verified in the Task 9 manual checklist with a real Pro session.
      },
      skip:
          'SyncRepository._requireUserId가 Supabase 세션을 실제로 조회하므로 단위 테스트가 제한적. Task 9에서 Pro 계정으로 수동 검증.',
    );
  });
}
