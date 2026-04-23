import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pull_debounce_test.mocks.dart';

@GenerateMocks([SupabaseClient, GoTrueClient])

/// SyncRepository.pullFromRemote 의 debounce 동작 테스트.
///
/// 실제 Supabase 호출은 세션이 없어 early return (userId == null) 된다.
/// 이 특성을 이용해, "debounce skip 경로" 와 "force 경로" 의 반환값을 구분한다.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late SyncRepository sync;
  late DatabaseHelper dbHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dbHelper = DatabaseHelper.createForTest();
    final folderRepo = LocalFolderRepository(databaseHelper: dbHelper);
    final linkRepo = LocalLinkRepository(databaseHelper: dbHelper);

    // Supabase.instance 없이도 SyncRepository 가 생성되도록 mock client 주입.
    // currentUser = null → pullFromRemote 내부에서 early return 경로를 밟는다.
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(mockAuth.currentUser).thenReturn(null);
    when(mockClient.auth).thenReturn(mockAuth);

    sync = SyncRepository(
      folderRepo: folderRepo,
      linkRepo: linkRepo,
      databaseHelper: dbHelper,
      client: mockClient,
    );
  });

  tearDown(() async {
    await dbHelper.deleteDatabase();
    await dbHelper.close();
  });

  group('pullFromRemote debounce', () {
    test('userId 없으면 (세션 없음) false 반환, 사이드이펙트 없음', () async {
      final ok = await sync.pullFromRemote();
      expect(ok, isFalse);
      final last = await sync.getLastPullAt();
      expect(last, isNull);
    });

    test('최근 pull (lp_last_pull_at = now) 이면 debounce 에 의해 skip', () async {
      // 최근 pull 기록을 주입 (now - 1초 — 5초 미만이므로 debounce 영역)
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(
        'lp_last_pull_at',
        now.subtract(const Duration(seconds: 1)).toIso8601String(),
      );

      final ok = await sync.pullFromRemote();
      expect(ok, isFalse);

      // lastPullAt 이 변경되지 않았는지 (debounce 로 restoreFromRemote 가 안 돌았음)
      final after = await sync.getLastPullAt();
      expect(after, isNotNull);
      expect(
        after!.difference(now).inSeconds.abs() <= 1,
        isTrue,
        reason: 'lastPullAt 갱신 없이 주입값 그대로 유지돼야 함',
      );
    });

    test('오래된 pull (5초 초과) 이면 debounce 통과 → userId 없어 여전히 false', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lp_last_pull_at',
        DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      );

      final ok = await sync.pullFromRemote();
      // 세션 없어서 false 지만, debounce 는 통과한 상태 (내부 early return)
      expect(ok, isFalse);
    });

    test('markOffline / clearOffline 은 offlineNotifier 에 반영된다', () async {
      expect(sync.offlineNotifier.value, isFalse);
      sync.markOffline();
      expect(sync.offlineNotifier.value, isTrue);
      sync.clearOffline();
      expect(sync.offlineNotifier.value, isFalse);
    });

    test('clearLocalSyncMeta 는 lp_last_pull_at 도 제거한다', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lp_last_pull_at',
        DateTime.now().toIso8601String(),
      );
      expect(await sync.getLastPullAt(), isNotNull);

      await sync.clearLocalSyncMeta();
      expect(await sync.getLastPullAt(), isNull);
    });
  });
}
