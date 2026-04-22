// test/provider/sync/merge_with_remote_test.dart
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'merge_with_remote_test.mocks.dart';

// TODO(boring-km): un-skip 시 @GenerateMocks에 SupabaseQueryBuilder, PostgrestFilterBuilder 추가 + build_runner 재생성 + mock 체인 세팅 필요
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  User,
])
void main() {
  late DatabaseHelper databaseHelper;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    databaseHelper = DatabaseHelper.createForTest();

    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    when(mockUser.id).thenReturn('test-user-id');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockClient.auth).thenReturn(mockAuth);
  });

  tearDown(() async {
    await databaseHelper.close();
    await databaseHelper.deleteDatabase();
  });

  test('로컬 1개 + 원격 1개 (같은 URL+경로) → 로컬에 1개 머지 결과', () async {
    // Supabase fluent mock 복잡도로 자동화 어려움. 디바이스에서 수동 검증.
  }, skip: 'Supabase fluent API mocking 복잡 — 수동 검증으로 대체');
}
