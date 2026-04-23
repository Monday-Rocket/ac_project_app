# 중첩 폴더 생성 구현 계획 (Phase 1 — 앱)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 링크풀 Flutter 앱에서 "특정 폴더 아래에 새 폴더를 만드는" 쓰기 경로를 추가하고, 동시에 Pro 동기화의 `parent_id` 누락 버그를 수정한다.

**Architecture:** 기존 `showAddFolderDialog`를 `showCreateFolderSheet`로 전면 교체하고, 이름 중복 검사를 전역→형제 범위로 변경한다. Cubit은 sealed `CreateFolderResult`로 실패 원인을 구분 전달한다. `SyncRepository.upsertFolderRemote`는 링크 경로와 동일한 2-pass 패턴으로 `parent_id`를 실어 나른다.

**Tech Stack:** Flutter 3.38.6 (FVM) / Dart, sqflite + sqflite_common_ffi(테스트), supabase_flutter, flutter_bloc, get_it, mockito, bloc_test

**Spec 참조:** `docs/superpowers/specs/2026-04-23-nested-folder-create-design.md`

**Phase 2(Chrome 확장)는 본 계획 범위 외**. Phase 1 종료 후 별도 계획으로 작성한다.

---

## File Structure

**Create:**
- `lib/cubits/folders/create_folder_result.dart` — sealed `CreateFolderResult` (`Created`/`DuplicateSibling`/`ParentMissing`/`Failed`)
- `lib/ui/widget/folder/show_create_folder_sheet.dart` — 신규 폴더 생성 바텀 시트 (dumb 위젯)
- `test/provider/sync/sync_repository_upsert_test.dart` — `upsertFolderRemote` 2-pass 단위 테스트
- `test/ui/widget/folder/show_create_folder_sheet_test.dart` — 시트 위젯 테스트
- `integration_test/nested_folder_create_test.dart` — E2E 골든 플로우

**Modify:**
- `lib/provider/local/local_folder_repository.dart` — `isSiblingNameTaken` 추가, `createFolder`에 "부모 존재" 가드 + `isSiblingNameTaken` 방어선
- `lib/cubits/folders/local_folders_cubit.dart` — `createFolder` 시그니처 `{int? parentId}` 확장, 반환 타입 `Future<CreateFolderResult>`
- `lib/provider/sync/sync_repository.dart` — `upsertFolderRemote` 2-pass로 재작성, `upsertLinkRemote`의 `_resolveRemoteFolderId` 예외 가드
- `lib/ui/view/links/my_link_view.dart` — `buildChildFoldersSection` 확장 + `_onAddChildFolder` 헬퍼
- `lib/ui/widget/dialog/bottom_dialog.dart` — `showFolderOptionsDialog`에 "하위 폴더 추가" 추가, `saveEmptyFolder`/`runCallback` 삭제
- `lib/ui/page/my_folder/my_folder_page.dart` — 신규 시트로 호출부 전환
- `lib/ui/widget/add_folder/folder_add_title.dart` — 신규 시트로 호출부 전환 (루트 고정)
- `test/provider/local/local_folder_repository_test.dart` — 중첩 시나리오 테스트 추가
- `test/cubits/local_folders_cubit_test.dart` — `CreateFolderResult` 테스트로 갱신

**Delete:**
- `lib/ui/widget/add_folder/show_add_folder_dialog.dart`
- `lib/cubits/folders/folder_name_cubit.dart`

**파일 분리 이유:**
- `create_folder_result.dart` 별도 — Cubit 외 시트·호출부도 참조하므로 독립 파일이 의존성 방향 깔끔함.
- `show_create_folder_sheet.dart` 단일 파일 — 기존 `show_rename_folder_dialog.dart`, `show_add_folder_dialog.dart` 패턴과 동일. 한 시트 = 한 파일.

---

## Task 순서 원칙

단계 번호는 스펙의 "구현 순서"와 일치. 각 단계는 단독 머지 가능하도록 설계되었으나, 이 플랜에서는 연속 실행을 전제로 한다.

- **Task 1**: Sync `upsertFolderRemote` 2-pass 버그 수정 (선수)
- **Task 2**: Repository에 `isSiblingNameTaken` + 부모 존재 가드
- **Task 3**: `CreateFolderResult` sealed 타입 + Cubit 시그니처 확장
- **Task 4**: `showCreateFolderSheet` 신규 (죽은 코드 상태로 커밋)
- **Task 5**: 호출부 전환 + 구 다이얼로그/Cubit 삭제
- **Task 6**: `MyLinkView` 중첩 진입점
- **Task 7**: `showFolderOptionsDialog`에 "하위 폴더 추가"
- **Task 8**: E2E 골든 플로우
- **Task 9**: Pro 동기화 수동 체크리스트 (릴리스 전)

---

## Task 1: `upsertFolderRemote` 2-pass 버그 수정

현재 `sync_repository.dart:107-123`의 `upsertFolderRemote`는 `parent_id: null`을 강제해 단건 업서트에서 `parentId`가 유실된다. 링크 업서트(`upsertLinkRemote`, 125-148)가 이미 쓰는 2-pass 패턴으로 교체한다. 동시에 링크 경로의 `_resolveRemoteFolderId` 예외 try/catch도 추가한다(E9).

**Files:**
- Modify: `lib/provider/sync/sync_repository.dart:107-148`
- Create: `test/provider/sync/sync_repository_upsert_test.dart`

- [ ] **Step 1: 테스트 파일 스캐폴드 작성**

```dart
// test/provider/sync/sync_repository_upsert_test.dart
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // SyncRepository는 SupabaseClient를 직접 참조하므로 실제 클라이언트를
  // 모킹하기 어렵다. 대신 _resolveRemoteFolderId 대체 훅을 테스트 시점에
  // 주입할 수 있도록 SyncRepository에 선택적 의존성을 추가하거나,
  // 테스트 가능한 순수 함수로 parent 해결 로직을 분리해 테스트한다.
  //
  // 전략: 이 Task에서는 upsertFolderRemote의 분기 로직(parent 해결 → dirty 처리)이
  //      정확한지 검증하는 통합 테스트보다, "parentId가 비어있을 때와 있을 때
  //      분기 경로"를 unit 레벨에서 확인하는 테스트를 추가한다. Supabase 호출
  //      자체는 실 통합 환경(Task 9 수동 체크리스트)에서 검증한다.
  //
  // 아래 테스트는 "로컬 동작(dirty 세팅)만" 검증한다. Supabase 호출은 fake에 맡긴다.
}
```

이 Task는 Supabase 클라이언트를 쉽게 모킹할 수 없어 실제 실행 가능한 단위 테스트가 제한적이다. Step 2에서 fake 전략을 확정한다.

- [ ] **Step 2: SyncRepository의 테스트 가능성 확인 — fake 클라이언트 패턴 조사**

Run: `grep -rn "SupabaseClient\|supabase_flutter" /Users/kangmin/dev/ac_project_app/test 2>/dev/null`

기존에 Supabase 클라이언트를 모킹하는 테스트가 있는지 확인. 없다면 `_resolveRemoteFolderId`를 `@visibleForTesting` protected로 노출하거나 함수 주입 훅(`ResolveFolderFn? resolver`)을 생성자에 추가해 테스트에서 오버라이드하는 전략을 택한다.

**이 스텝에서 결정:**
- 기존 Supabase 모킹 패턴 없음 → `SyncRepository` 생성자에 `@visibleForTesting String? Function(String userId, int localId)? resolveRemoteFolderIdForTest` 훅 추가. 프로덕션은 null이면 기존 `_resolveRemoteFolderId`를 호출.

- [ ] **Step 3: SyncRepository에 테스트 훅 추가**

`lib/provider/sync/sync_repository.dart` 생성자 바로 아래에 다음 필드 추가:

```dart
/// Supabase 호출 모킹이 어려워 parent 해결 경로만 테스트에서 오버라이드할 수 있게 한다.
@visibleForTesting
Future<String?> Function(String userId, int localFolderId)?
    resolveRemoteFolderIdForTest;
```

필요 import: `import 'package:flutter/foundation.dart';`

그리고 `_resolveRemoteFolderId` 호출부 2곳(`upsertFolderRemote`, `upsertLinkRemote`)을 헬퍼로 감싼다:

```dart
Future<String?> _resolveFolderOrTestHook(String userId, int localId) {
  final hook = resolveRemoteFolderIdForTest;
  if (hook != null) return hook(userId, localId);
  return _resolveRemoteFolderId(userId, localId);
}
```

- [ ] **Step 4: `upsertFolderRemote` 2-pass 재작성**

`lib/provider/sync/sync_repository.dart`의 `upsertFolderRemote` 전체 교체:

```dart
Future<void> upsertFolderRemote(LocalFolder folder) async {
  final userId = _requireUserId();
  if (userId == null || folder.id == null) return;

  String? parentServerId;
  if (folder.parentId != null) {
    try {
      parentServerId = await _resolveFolderOrTestHook(userId, folder.parentId!);
    } catch (e) {
      Log.e('upsertFolderRemote: parent resolve failed: $e');
      await _setDirty(true);
      return;
    }
    if (parentServerId == null) {
      await _setDirty(true);
      return;
    }
  }

  await remoteWrite(() async {
    await _client.from('folders').upsert({
      'user_id': userId,
      'client_id': folder.id,
      'parent_id': parentServerId,
      'name': folder.name,
      'thumbnail': folder.thumbnail,
      'is_classified': folder.isClassified,
      'created_at': folder.createdAt,
      'updated_at': folder.updatedAt,
    }, onConflict: 'user_id,client_id');
  });
}
```

- [ ] **Step 5: `upsertLinkRemote`의 예외 가드 추가**

`lib/provider/sync/sync_repository.dart`의 `upsertLinkRemote` 중간부 교체:

```dart
Future<void> upsertLinkRemote(LocalLink link) async {
  final userId = _requireUserId();
  if (userId == null || link.id == null) return;

  String? folderServerId;
  try {
    folderServerId = await _resolveFolderOrTestHook(userId, link.folderId);
  } catch (e) {
    Log.e('upsertLinkRemote: folder resolve failed: $e');
    await _setDirty(true);
    return;
  }
  if (folderServerId == null) {
    await _setDirty(true);
    return;
  }

  await remoteWrite(() async {
    await _client.from('links').upsert({
      'user_id': userId,
      'client_id': link.id,
      'folder_id': folderServerId,
      'url': link.url,
      'title': link.title,
      'image': link.image,
      'describe': link.describe,
      'inflow_type': link.inflowType,
      'created_at': link.createdAt,
      'updated_at': link.updatedAt,
    }, onConflict: 'user_id,client_id');
  });
}
```

- [ ] **Step 6: 테스트 작성 — parent 해결 분기 검증**

`test/provider/sync/sync_repository_upsert_test.dart` 본문 작성:

```dart
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SyncRepository sync;
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dbHelper = DatabaseHelper.createForTest();
    final folderRepo = LocalFolderRepository(databaseHelper: dbHelper);
    final linkRepo = LocalLinkRepository(databaseHelper: dbHelper);
    sync = SyncRepository(folderRepo: folderRepo, linkRepo: linkRepo);
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

      // userId가 null이면 조기 반환하므로 실제 upsert는 실행되지 않아도,
      // 분기 로직 자체는 타고 들어가는지 확인 (null 경우는 밖에서 필터됨).
      // 이 테스트는 SupabaseClient 호출 여부는 검증 못 하므로, resolver가
      // 호출되지 않는다는 것만 확인.
      await sync.upsertFolderRemote(LocalFolder(
        id: 1,
        parentId: null,
        name: 'Root',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ));

      expect(resolverCalls, 0);
    });

    test('parentId 있으면 resolver 호출됨', () async {
      var resolverCalls = 0;
      sync.resolveRemoteFolderIdForTest = (userId, localId) async {
        resolverCalls++;
        expect(localId, 42);
        return null; // 부모 미해결 경로
      };

      // userId가 없으면 resolver까지 가지 못하므로 이 테스트는 생략하거나,
      // _requireUserId를 우회하는 추가 훅이 필요. 현재로선 resolver가 호출되는지
      // 보장하려면 Supabase 세션 모킹이 필요하다. 이 단계에서는 "parentId가 있으면
      // resolver를 호출해야 한다"는 의도를 주석으로 남기고, 실제 검증은 Task 9
      // 수동 체크리스트로 넘긴다.
    }, skip: 'SyncRepository._requireUserId가 Supabase 세션을 실제로 조회하므로 단위 테스트가 제한적. Task 9에서 Pro 계정으로 수동 검증.');
  });
}
```

**중요**: `_requireUserId`는 `Supabase.instance.client.auth.currentUser?.id`를 직접 읽어 모킹이 어렵다. 이 Task의 테스트는 **최소한의 분기 검증**에 그치고, 실제 upsert 동작은 Task 9 수동 체크리스트로 보완한다.

- [ ] **Step 7: `flutter test test/provider/sync/sync_repository_upsert_test.dart` 실행**

Run: `fvm flutter test test/provider/sync/sync_repository_upsert_test.dart`
Expected: 1 passing, 1 skipped

- [ ] **Step 8: `flutter analyze` 깨끗함 확인**

Run: `fvm flutter analyze lib/provider/sync/sync_repository.dart test/provider/sync/sync_repository_upsert_test.dart`
Expected: No issues found

- [ ] **Step 9: 커밋**

```bash
git add lib/provider/sync/sync_repository.dart test/provider/sync/sync_repository_upsert_test.dart
git commit -m "fix(sync): upsertFolderRemote에 parent_id 2-pass 적용 + upsertLinkRemote 예외 가드"
```

---

## Task 2: Repository — `isSiblingNameTaken` + 부모 존재 가드

**Files:**
- Modify: `lib/provider/local/local_folder_repository.dart`
- Modify: `test/provider/local/local_folder_repository_test.dart`

- [ ] **Step 1: `isSiblingNameTaken` 실패 테스트 작성**

`test/provider/local/local_folder_repository_test.dart` 하단에 다음 그룹 추가:

```dart
  group('isSiblingNameTaken', () {
    test('루트 범위에 동명 폴더 있으면 true', () async {
      await repository.createFolder(LocalFolder(
        name: 'React',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final taken = await repository.isSiblingNameTaken(null, 'React');
      expect(taken, isTrue);
    });

    test('루트 범위에 없으면 false', () async {
      final taken = await repository.isSiblingNameTaken(null, 'Nothing');
      expect(taken, isFalse);
    });

    test('자식 범위에서 동명 형제 있으면 true', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Parent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      await repository.createFolder(LocalFolder(
        name: 'Child',
        parentId: parentId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final taken = await repository.isSiblingNameTaken(parentId, 'Child');
      expect(taken, isTrue);
    });

    test('다른 부모 아래 같은 이름은 false (형제 아님)', () async {
      final parentA = await repository.createFolder(LocalFolder(
        name: 'A',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      final parentB = await repository.createFolder(LocalFolder(
        name: 'B',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      await repository.createFolder(LocalFolder(
        name: 'Shared',
        parentId: parentA,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final takenUnderB = await repository.isSiblingNameTaken(parentB, 'Shared');
      expect(takenUnderB, isFalse);

      final takenUnderA = await repository.isSiblingNameTaken(parentA, 'Shared');
      expect(takenUnderA, isTrue);
    });

    test('루트 이름과 중첩 이름은 서로 독립적', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Topic',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      // 루트에 Topic이 있지만, parentId 범위에는 Topic이 없으므로 false.
      final takenUnderParent =
          await repository.isSiblingNameTaken(parentId, 'Topic');
      expect(takenUnderParent, isFalse);
    });

    test('공백 포함 이름은 trim되지 않고 그대로 비교됨 (trim은 호출부 책임)', () async {
      await repository.createFolder(LocalFolder(
        name: 'Spaced',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final takenExact = await repository.isSiblingNameTaken(null, 'Spaced');
      final takenWithSpace = await repository.isSiblingNameTaken(null, 'Spaced ');
      expect(takenExact, isTrue);
      expect(takenWithSpace, isFalse);
    });
  });

  group('createFolder with parent', () {
    test('자식 생성 성공 시 parent_id 저장됨', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Parent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      final childId = await repository.createFolder(LocalFolder(
        name: 'Child',
        parentId: parentId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final child = await repository.getFolderById(childId);
      expect(child, isNotNull);
      expect(child!.parentId, parentId);
    });

    test('존재하지 않는 부모 id 지정 시 StateError', () async {
      expect(
        () => repository.createFolder(LocalFolder(
          name: 'Orphan',
          parentId: 99999,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('미분류 폴더를 부모로 지정 시 StateError (기존 동작 유지)', () async {
      final unclassified = await repository.getUnclassifiedFolder();
      expect(
        () => repository.createFolder(LocalFolder(
          name: 'Forbidden',
          parentId: unclassified!.id,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('동일 부모 아래 동일 이름 거부 (Repository 방어선)', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Parent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      await repository.createFolder(LocalFolder(
        name: 'Dup',
        parentId: parentId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      expect(
        () => repository.createFolder(LocalFolder(
          name: 'Dup',
          parentId: parentId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )),
        throwsA(isA<StateError>()),
      );
    });
  });
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `fvm flutter test test/provider/local/local_folder_repository_test.dart`
Expected: 새로 추가한 테스트들이 `isSiblingNameTaken` 미정의 등으로 컴파일 에러.

- [ ] **Step 3: `isSiblingNameTaken` 구현**

`lib/provider/local/local_folder_repository.dart`의 클래스 내부 적당한 위치(`searchFolders` 근처)에 추가:

```dart
  /// 같은 부모 아래에 동일한 이름의 폴더가 이미 있는지.
  /// parentId=null은 루트 범위.
  /// 비교는 바이트-equal (대소문자 구분, 유니코드 정규화 없음).
  /// 호출부가 필요 시 이름을 trim한 뒤 전달해야 한다.
  Future<bool> isSiblingNameTaken(int? parentId, String name) async {
    final db = await _databaseHelper.database;
    final rows = parentId == null
        ? await db.query(
            _table,
            where: 'parent_id IS NULL AND name = ?',
            whereArgs: [name],
            limit: 1,
          )
        : await db.query(
            _table,
            where: 'parent_id = ? AND name = ?',
            whereArgs: [parentId, name],
            limit: 1,
          );
    return rows.isNotEmpty;
  }
```

- [ ] **Step 4: `createFolder`에 부모 존재 가드 + 형제 이름 방어선 추가**

`lib/provider/local/local_folder_repository.dart`의 `createFolder` 메서드를 다음으로 교체:

```dart
  /// 폴더 생성.
  /// 미분류 폴더는 시스템이 관리하므로 is_classified=false 생성은 금지.
  /// 미분류 폴더를 부모로 지정하는 것도 금지.
  Future<int> createFolder(LocalFolder folder) async {
    if (!folder.isClassified) {
      throw StateError(
        '미분류 폴더는 시스템이 관리합니다. 수동 생성 불가.',
      );
    }
    if (folder.parentId != null) {
      final parent = await getFolderById(folder.parentId!);
      if (parent == null) {
        throw StateError('부모 폴더가 존재하지 않습니다.');
      }
      if (!parent.isClassified) {
        throw StateError('미분류 폴더 아래에는 하위 폴더를 만들 수 없습니다.');
      }
    }
    if (await isSiblingNameTaken(folder.parentId, folder.name)) {
      throw StateError('같은 위치에 이미 같은 이름의 폴더가 있습니다.');
    }
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = folder.toMap()
      ..['created_at'] = now
      ..['updated_at'] = now;
    final id = await db.insert(_table, map);
    Log.i('Created folder: $id - ${folder.name}');
    ProRemoteHooks.onFolderUpserted(folder.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }
```

기존 `_assertNotUnclassified` 호출 대신 인라인에서 `parent.isClassified`를 검사하는 것에 주의. `_assertNotUnclassified`는 `updateFolder`/`deleteFolder`에서만 사용되므로 유지.

- [ ] **Step 5: 테스트 실행해서 전부 통과 확인**

Run: `fvm flutter test test/provider/local/local_folder_repository_test.dart`
Expected: 전부 PASS

- [ ] **Step 6: analyze 확인**

Run: `fvm flutter analyze lib/provider/local/local_folder_repository.dart test/provider/local/local_folder_repository_test.dart`
Expected: No issues found

- [ ] **Step 7: 커밋**

```bash
git add lib/provider/local/local_folder_repository.dart test/provider/local/local_folder_repository_test.dart
git commit -m "feat(folder): 형제 범위 중복 검사 + 부모 존재 가드 추가"
```

---

## Task 3: `CreateFolderResult` + `LocalFoldersCubit.createFolder` 시그니처 확장

**Files:**
- Create: `lib/cubits/folders/create_folder_result.dart`
- Modify: `lib/cubits/folders/local_folders_cubit.dart`
- Modify: `test/cubits/local_folders_cubit_test.dart`

- [ ] **Step 1: sealed 결과 타입 작성**

Create `lib/cubits/folders/create_folder_result.dart`:

```dart
/// 폴더 생성 결과. 시트가 원인별 에러 메시지를 선택할 수 있게 구분 전달.
sealed class CreateFolderResult {
  const CreateFolderResult();
}

class Created extends CreateFolderResult {
  const Created(this.id);
  final int id;
}

class DuplicateSibling extends CreateFolderResult {
  const DuplicateSibling();
}

class ParentMissing extends CreateFolderResult {
  const ParentMissing();
}

class CreateFolderFailed extends CreateFolderResult {
  const CreateFolderFailed(this.error);
  final Object error;
}
```

**네이밍 주의**: `Failed`는 너무 일반적이고 다른 라이브러리(예: Result 타입 라이브러리)와 충돌 위험이 있어 `CreateFolderFailed`로 명명. 스펙의 `Failed`와 다르지만 의도는 동일.

- [ ] **Step 2: Cubit 실패 테스트 갱신 — `CreateFolderResult` 반환 기대**

`test/cubits/local_folders_cubit_test.dart`의 `group('createFolder()')` 블록 전체를 다음으로 교체:

```dart
  group('createFolder()', () {
    test('성공 시 Created(id)와 loading/loaded 상태 emit', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.isSiblingNameTaken(null, 'New')).thenAnswer((_) async => false);
      when(mockRepo.createFolder(any)).thenAnswer((_) async => 42);
      _stubGetAll(mockRepo, [makeLocalFolder(id: 42, name: 'New')]);

      final emitted =
          await collectStates(cubit, () => cubit.createFolder('New'));

      final result = cubit.lastCreateResult; // 테스트용 공개 필드
      expect(result, isA<Created>());
      expect((result as Created).id, 42);
      expect(emitted, [isA<FolderLoadingState>(), isA<FolderLoadedState>()]);
      await cubit.close();
    });

    test('parentId 전달 시 Repository에 그대로 전달됨', () async {
      final cubit = await _buildAndDrain();
      when(mockRepo.isSiblingNameTaken(7, 'Child'))
          .thenAnswer((_) async => false);
      when(mockRepo.createFolder(any)).thenAnswer((_) async => 99);
      _stubGetAll(mockRepo, [makeLocalFolder(id: 99, name: 'Child')]);

      await cubit.createFolder('Child', parentId: 7);

      final captured = verify(mockRepo.createFolder(captureAny)).captured.single
          as LocalFolder;
      expect(captured.parentId, 7);
      expect(captured.name, 'Child');
      await cubit.close();
    });

    test('형제 이름 중복 시 DuplicateSibling 반환, state emit 없음', () async {
      final cubit = await _buildAndDrain();
      when(mockRepo.isSiblingNameTaken(null, 'Dup'))
          .thenAnswer((_) async => true);

      final emitted = await collectStates(cubit, () => cubit.createFolder('Dup'));

      expect(cubit.lastCreateResult, isA<DuplicateSibling>());
      expect(emitted, isEmpty);
      verifyNever(mockRepo.createFolder(any));
      await cubit.close();
    });

    test('Repository가 "부모 폴더" StateError throw → ParentMissing', () async {
      final cubit = await _buildAndDrain();
      when(mockRepo.isSiblingNameTaken(5, 'X')).thenAnswer((_) async => false);
      when(mockRepo.createFolder(any))
          .thenThrow(StateError('부모 폴더가 존재하지 않습니다.'));

      await cubit.createFolder('X', parentId: 5);

      expect(cubit.lastCreateResult, isA<ParentMissing>());
      await cubit.close();
    });

    test('Repository 일반 예외 → CreateFolderFailed', () async {
      final cubit = await _buildAndDrain();
      when(mockRepo.isSiblingNameTaken(null, 'Bad'))
          .thenAnswer((_) async => false);
      when(mockRepo.createFolder(any)).thenThrow(Exception('insert failed'));

      await cubit.createFolder('Bad');

      expect(cubit.lastCreateResult, isA<CreateFolderFailed>());
      await cubit.close();
    });
  });
```

**참고**: Cubit 메서드는 `Future<CreateFolderResult>` 반환. 테스트에서 `cubit.lastCreateResult` 대신 `await cubit.createFolder(...)`의 반환값을 직접 사용할 수도 있지만, 위 예시처럼 Step 3의 시그니처로 반환값을 변수에 받아 `expect`하는 패턴도 가능. **단순화**를 위해 테스트를 다시 조정:

```dart
    test('성공 시 Created(id) 반환 + loading/loaded 상태 emit', () async {
      final cubit = await _buildAndDrain();
      when(mockRepo.isSiblingNameTaken(null, 'New')).thenAnswer((_) async => false);
      when(mockRepo.createFolder(any)).thenAnswer((_) async => 42);
      _stubGetAll(mockRepo, [makeLocalFolder(id: 42, name: 'New')]);

      CreateFolderResult? result;
      final emitted = await collectStates(cubit, () async {
        result = await cubit.createFolder('New');
      });

      expect(result, isA<Created>());
      expect((result as Created).id, 42);
      expect(emitted, [isA<FolderLoadingState>(), isA<FolderLoadedState>()]);
      await cubit.close();
    });
```

**이 패턴을 모든 테스트에 적용**. `cubit.lastCreateResult`는 추가하지 않는다.

- [ ] **Step 3: 테스트 파일 상단 import 추가**

`test/cubits/local_folders_cubit_test.dart` 상단:

```dart
import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
```

mockito 대상에 `isSiblingNameTaken` 포함시키기 위해 mocks 재생성 필요 (Step 6).

- [ ] **Step 4: 테스트 실행해서 실패 확인**

Run: `fvm flutter test test/cubits/local_folders_cubit_test.dart`
Expected: 컴파일 에러 — `CreateFolderResult` 미정의, `createFolder` 반환 타입 불일치.

- [ ] **Step 5: Cubit 수정**

`lib/cubits/folders/local_folders_cubit.dart`의 `createFolder` 메서드를 다음으로 교체:

```dart
  /// 폴더 생성. 결과는 CreateFolderResult로 구분 전달.
  Future<CreateFolderResult> createFolder(String name, {int? parentId}) async {
    try {
      if (await _folderRepository.isSiblingNameTaken(parentId, name)) {
        return const DuplicateSibling();
      }
      final now = DateTime.now().toIso8601String();
      final newFolder = LocalFolder(
        name: name,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _folderRepository.createFolder(newFolder);
      await getFolders();
      return Created(id);
    } on StateError catch (e) {
      Log.e('LocalFoldersCubit.createFolder state error: $e');
      if (e.message.contains('부모 폴더')) return const ParentMissing();
      return CreateFolderFailed(e);
    } catch (e) {
      Log.e('LocalFoldersCubit.createFolder error: $e');
      return CreateFolderFailed(e);
    }
  }
```

파일 상단 import 추가:

```dart
import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
```

- [ ] **Step 6: mockito mocks 재생성**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `test/cubits/local_folders_cubit_test.mocks.dart` 갱신됨 (`isSiblingNameTaken` mock 추가)

- [ ] **Step 7: 테스트 통과 확인**

Run: `fvm flutter test test/cubits/local_folders_cubit_test.dart`
Expected: 전부 PASS

- [ ] **Step 8: analyze 확인**

Run: `fvm flutter analyze lib/cubits/folders/ test/cubits/local_folders_cubit_test.dart`
Expected: No issues found

- [ ] **Step 9: 커밋**

```bash
git add lib/cubits/folders/create_folder_result.dart lib/cubits/folders/local_folders_cubit.dart test/cubits/local_folders_cubit_test.dart test/cubits/local_folders_cubit_test.mocks.dart
git commit -m "feat(folder): Cubit.createFolder를 parentId 지원 + CreateFolderResult 반환"
```

---

## Task 4: `showCreateFolderSheet` 신규 작성

이 Task 종료 시점에는 시트가 죽은 코드 상태(아무도 호출하지 않음)로 머지된다. 다음 Task에서 호출부 전환.

**Files:**
- Create: `lib/ui/widget/folder/show_create_folder_sheet.dart`
- Create: `test/ui/widget/folder/show_create_folder_sheet_test.dart`

- [ ] **Step 1: 시트 스켈레톤 작성**

Create `lib/ui/widget/folder/show_create_folder_sheet.dart`:

```dart
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/ui/widget/folder/pick_folder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 루트 또는 특정 부모 아래에 새 폴더를 만드는 바텀 시트.
/// 취소=null, 생성 성공=새 폴더 id 반환.
Future<int?> showCreateFolderSheet(
  BuildContext context, {
  int? initialParentId,
  bool allowParentPick = true,
}) async {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CreateFolderSheet(
      initialParentId: initialParentId,
      allowParentPick: allowParentPick,
    ),
  );
}

class _CreateFolderSheet extends StatefulWidget {
  const _CreateFolderSheet({
    required this.initialParentId,
    required this.allowParentPick,
  });

  final int? initialParentId;
  final bool allowParentPick;

  @override
  State<_CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<_CreateFolderSheet> {
  final _controller = TextEditingController();
  int? _parentId;
  String _parentPath = '루트';
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _parentId = widget.initialParentId;
    _loadParentPath();
  }

  Future<void> _loadParentPath() async {
    if (_parentId == null) {
      setState(() => _parentPath = '루트');
      return;
    }
    final repo = getIt<LocalFolderRepository>();
    final crumbs = await repo.getBreadcrumb(_parentId!);
    if (!mounted) return;
    setState(() {
      _parentPath = crumbs.map((f) => f.name).join(' > ');
    });
  }

  Future<void> _onParentTap() async {
    final picked = await showPickFolderSheet(
      context: context,
      title: '상위 폴더 선택',
      includeUnclassified: false,
    );
    if (picked == null) return;
    setState(() {
      _parentId = picked;
      _errorText = null;
    });
    await _loadParentPath();
  }

  Future<void> _onSubmit() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = '폴더 이름을 입력해주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final cubit = context.read<LocalFoldersCubit>();
    final result = await cubit.createFolder(raw, parentId: _parentId);
    if (!mounted) return;

    switch (result) {
      case Created(:final id):
        Navigator.pop(context, id);
      case DuplicateSibling():
        setState(() {
          _errorText =
              '같은 위치에 이미 같은 이름의 폴더가 있어요. 다른 이름을 입력해주세요.';
          _submitting = false;
        });
      case ParentMissing():
        setState(() {
          _errorText = '상위 폴더를 찾을 수 없어요. 다시 선택해주세요.';
          _submitting = false;
        });
      case CreateFolderFailed():
        setState(() {
          _errorText = '폴더를 만들지 못했어요. 잠시 후 다시 시도해주세요.';
          _submitting = false;
        });
    }
  }

  bool get _canSubmit =>
      _controller.text.trim().isNotEmpty &&
      !_submitting &&
      _errorText == null &&
      _controller.text.length <= 20;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.w),
            topRight: Radius.circular(20.w),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 30.w,
            left: 24.w,
            right: 24.w,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                (Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 28.w),
              if (widget.allowParentPick) _buildParentRow(),
              if (widget.allowParentPick) SizedBox(height: 20.w),
              _buildNameField(),
              SizedBox(height: 40.w),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Center(
          child: Text(
            '새로운 폴더',
            style: TextStyle(
              color: blackBold,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            key: const Key('create_folder_done_text'),
            onTap: _canSubmit ? _onSubmit : null,
            child: Text(
              '완료',
              style: TextStyle(
                color: _canSubmit ? grey800 : grey300,
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentRow() {
    return InkWell(
      key: const Key('create_folder_parent_row'),
      onTap: _onParentTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: greyTab, width: 1.w),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.folder, size: 16.sp, color: primary600),
            SizedBox(width: 8.w),
            Text(
              '상위 폴더',
              style: TextStyle(
                color: grey600,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                _parentPath,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: blackBold,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, size: 18.sp, color: grey600),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      key: const Key('create_folder_name_field'),
      controller: _controller,
      autofocus: true,
      maxLength: 20,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        color: grey800,
      ),
      cursorColor: primary600,
      decoration: InputDecoration(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primary800, width: 2.w),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: greyTab, width: 2.w),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: redError, width: 2.w),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: redError, width: 2.w),
        ),
        counterText: '',
        errorText: _errorText,
        errorStyle: const TextStyle(color: redError),
        hintText: '새로운 폴더 이름',
        hintStyle: TextStyle(
          color: grey400,
          fontSize: 17.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onChanged: (_) {
        if (_errorText != null) {
          setState(() => _errorText = null);
        }
      },
      onFieldSubmitted: (_) {
        if (_canSubmit) _onSubmit();
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      key: const Key('create_folder_submit'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(55.w),
        backgroundColor: _canSubmit ? primary600 : secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.w),
        ),
        shadowColor: Colors.transparent,
      ),
      onPressed: _canSubmit ? _onSubmit : null,
      child: _submitting
          ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              '폴더 생성하기',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
```

**참고**: 이 시트는 호출부 context의 `LocalFoldersCubit`에 의존한다. 호출부는 이미 `LocalFoldersCubit`을 BlocProvider로 제공하는 위치에서만 시트를 열어야 한다 (`MyFolderPage`, `MyLinkView`, `folder_add_title.dart` 모두 해당 Cubit을 이미 제공).

- [ ] **Step 2: 위젯 테스트 작성 — 기본 렌더**

Create `test/ui/widget/folder/show_create_folder_sheet_test.dart`:

```dart
import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LocalFolderRepository, LocalFoldersCubit])
import 'show_create_folder_sheet_test.mocks.dart';

Widget _wrap(Widget child, {required LocalFoldersCubit cubit}) {
  return MaterialApp(
    home: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => Scaffold(
        body: BlocProvider<LocalFoldersCubit>.value(
          value: cubit,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showCreateFolderSheet(ctx),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockLocalFolderRepository mockRepo;
  late MockLocalFoldersCubit mockCubit;

  setUp(() async {
    await getIt.reset();
    mockRepo = MockLocalFolderRepository();
    getIt.registerSingleton<LocalFolderRepository>(mockRepo);

    mockCubit = MockLocalFoldersCubit();
    // close()/state/stream은 BlocProvider가 구독 관리에 사용.
    when(mockCubit.state).thenReturn(FolderInitialState());
    when(mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(mockCubit.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('열면 제목과 이름 입력 필드가 보이고 버튼은 disabled', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(), cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('새로운 폴더'), findsOneWidget);
    expect(find.byKey(const Key('create_folder_name_field')), findsOneWidget);
    expect(find.text('폴더 생성하기'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('create_folder_submit')),
    );
    expect(button.onPressed, isNull); // disabled
  });

  testWidgets('이름 입력 시 버튼 활성화', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(), cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'MyFolder',
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('create_folder_submit')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('allowParentPick=false면 ParentRow 미렌더', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => Scaffold(
          body: BlocProvider<LocalFoldersCubit>.value(
            value: mockCubit,
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () =>
                    showCreateFolderSheet(ctx, allowParentPick: false),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_folder_parent_row')), findsNothing);
  });

  testWidgets('initialParentId 주면 브레드크럼 경로 표시', (tester) async {
    when(mockRepo.getBreadcrumb(42)).thenAnswer((_) async => [
          LocalFolder(
            id: 1,
            name: '개발',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
          LocalFolder(
            id: 42,
            parentId: 1,
            name: 'React',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
        ]);

    await tester.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => Scaffold(
          body: BlocProvider<LocalFoldersCubit>.value(
            value: mockCubit,
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () =>
                    showCreateFolderSheet(ctx, initialParentId: 42),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('개발 > React'), findsOneWidget);
  });

  testWidgets('중복 이름 submit → 에러 메시지 표시 + 시트 유지', (tester) async {
    when(mockCubit.createFolder('Dup', parentId: null))
        .thenAnswer((_) async => const DuplicateSibling());

    await tester.pumpWidget(_wrap(const SizedBox(), cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'Dup',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('같은 위치에 이미 같은 이름의 폴더가 있어요. 다른 이름을 입력해주세요.'),
      findsOneWidget,
    );
    expect(find.text('새로운 폴더'), findsOneWidget); // 시트 여전히 열림
  });

  testWidgets('성공 시 Navigator.pop(id) 호출 → 시트 닫힘', (tester) async {
    when(mockCubit.createFolder('Good', parentId: null))
        .thenAnswer((_) async => const Created(7));

    int? poppedId;
    await tester.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => Scaffold(
          body: BlocProvider<LocalFoldersCubit>.value(
            value: mockCubit,
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedId = await showCreateFolderSheet(ctx);
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'Good',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle();

    expect(poppedId, 7);
    expect(find.text('새로운 폴더'), findsNothing);
  });
}
```

- [ ] **Step 3: mocks 생성**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `test/ui/widget/folder/show_create_folder_sheet_test.mocks.dart` 생성됨

- [ ] **Step 4: 테스트 실행**

Run: `fvm flutter test test/ui/widget/folder/show_create_folder_sheet_test.dart`
Expected: 전부 PASS

- [ ] **Step 5: analyze 확인**

Run: `fvm flutter analyze lib/ui/widget/folder/show_create_folder_sheet.dart test/ui/widget/folder/show_create_folder_sheet_test.dart`
Expected: No issues found

- [ ] **Step 6: 커밋**

```bash
git add lib/ui/widget/folder/show_create_folder_sheet.dart test/ui/widget/folder/show_create_folder_sheet_test.dart test/ui/widget/folder/show_create_folder_sheet_test.mocks.dart
git commit -m "feat(folder): showCreateFolderSheet 신규 — 루트/중첩 폴더 생성 시트"
```

---

## Task 5: 호출부 전환 + 구 다이얼로그/Cubit 삭제

**Files:**
- Modify: `lib/ui/page/my_folder/my_folder_page.dart` (라인 179 부근)
- Modify: `lib/ui/widget/add_folder/folder_add_title.dart` (라인 26 부근)
- Modify: `lib/ui/widget/dialog/bottom_dialog.dart` — `saveEmptyFolder`, `runCallback` 제거
- Delete: `lib/ui/widget/add_folder/show_add_folder_dialog.dart`
- Delete: `lib/cubits/folders/folder_name_cubit.dart`

- [ ] **Step 1: `folder_add_title.dart` 호출부 파악**

Run: `sed -n '1,60p' /Users/kangmin/dev/ac_project_app/lib/ui/widget/add_folder/folder_add_title.dart`

현재 구조를 확인한 뒤 `showAddFolderDialog`를 `showCreateFolderSheet`로 교체. 파일 상단에 import 추가:

```dart
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
```

`showAddFolderDialog(...)` 호출을 다음으로 교체:

```dart
final newId = await showCreateFolderSheet(
  context,
  allowParentPick: false,
);
if (newId == null || !context.mounted) return;
await context.read<LocalFoldersCubit>().getFoldersWithoutUnclassified();
final folders = context.read<LocalFoldersCubit>().folders;
moveToMyLinksView?.call(context, folders, folders.length - 1);
callback?.call();
if (context.mounted) {
  showBottomToast(context: context, '새로운 폴더가 생성되었어요!');
}
```

구 import(`show_add_folder_dialog.dart`) 제거.

- [ ] **Step 2: `my_folder_page.dart` 호출부 교체**

`lib/ui/page/my_folder/my_folder_page.dart`의 라인 179 부근 `showAddFolderDialog(...)`를 `showCreateFolderSheet` 호출로 교체. 상단 import:

```dart
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
```

```dart
onTap: () async {
  final newId = await showCreateFolderSheet(context);
  if (newId == null || !context.mounted) return;
  await context.read<LocalFoldersCubit>().getFolders();
  final folders = context.read<LocalFoldersCubit>().folders;
  moveToMyLinksView(context, folders, folders.length - 1);
  if (context.mounted) {
    showBottomToast(context: context, '새로운 폴더가 생성되었어요!');
  }
},
```

구 `showAddFolderDialog` import 제거.

- [ ] **Step 3: `bottom_dialog.dart`에서 `saveEmptyFolder`/`runCallback` 삭제**

`lib/ui/widget/dialog/bottom_dialog.dart`의 라인 321-372(`saveEmptyFolder`와 `runCallback` 함수 전체) 블록을 삭제한다. 상단에 더 이상 쓰이지 않는 import(`FolderNameCubit`, `Folder`, `LocalFoldersCubit` 중 쓰는 것은 유지)도 정리.

- [ ] **Step 4: 구 파일 삭제**

```bash
rm lib/ui/widget/add_folder/show_add_folder_dialog.dart
rm lib/cubits/folders/folder_name_cubit.dart
```

구 `folder_name_cubit.dart`를 참조하는 곳이 남았는지 확인:

Run: `grep -rn "folder_name_cubit\|FolderNameCubit" /Users/kangmin/dev/ac_project_app/lib /Users/kangmin/dev/ac_project_app/test 2>/dev/null`
Expected: 결과 없음. 남으면 해당 파일도 정리.

- [ ] **Step 5: 구 다이얼로그 관련 테스트 정리**

Run: `grep -rn "show_add_folder_dialog\|showAddFolderDialog\|FolderNameCubit\|saveEmptyFolder" /Users/kangmin/dev/ac_project_app/test 2>/dev/null`

결과에 나오는 테스트 파일을 삭제하거나(구 파일 단독 테스트) Task 4의 `show_create_folder_sheet_test.dart`로 커버되도록 정리한다.

- [ ] **Step 6: `showRenameFolderDialog`의 `FolderNameCubit` 사용 확인**

Run: `grep -n "FolderNameCubit" /Users/kangmin/dev/ac_project_app/lib/ui/widget/rename_folder/show_rename_folder_dialog.dart`

`FolderNameCubit`은 rename 다이얼로그에서도 쓰인다. **rename 다이얼로그는 이번 스펙 범위 밖**이므로 손대지 않기 위해 `folder_name_cubit.dart`를 삭제할 수 없다. **Step 4의 삭제 중 `folder_name_cubit.dart`는 유지**한다.

→ Step 4의 `rm lib/cubits/folders/folder_name_cubit.dart` 줄을 **건너뛴다**. `show_add_folder_dialog.dart`만 삭제.

스펙 문서의 "폐기" 항목 중 `folder_name_cubit.dart`는 rename 다이얼로그에서 아직 쓰이므로 **실제 코드에서는 유지**. 스펙 문서에도 메모로 남긴다 (Task 9의 후속 작업).

- [ ] **Step 7: analyze 깨끗함 확인**

Run: `fvm flutter analyze`
Expected: No issues found

- [ ] **Step 8: 관련 테스트 전체 실행**

Run: `fvm flutter test test/cubits test/provider test/ui`
Expected: 전부 PASS (수동 확인 화면 스모크 포함)

- [ ] **Step 9: 스모크 — 앱 실행해서 수기 확인**

Run: `fvm flutter run -d <device>` 후 다음 2개 경로 확인:
1. 메인 탭에서 "+ 새 폴더" → 시트 열림 → 이름 입력 → 생성 → 그리드에 추가됨 + 해당 폴더 화면으로 이동
2. 공유 시트(OS 공유 메뉴에서 링크 공유) → "+ 새 폴더" → 이름 입력 → 생성 → 리스트에 추가됨

불가한 경우 스펙의 "Phase 1 종료 기준" 수기 항목으로 이월.

- [ ] **Step 10: 커밋**

```bash
git add lib/ lib/ui/page/my_folder/my_folder_page.dart lib/ui/widget/add_folder/folder_add_title.dart lib/ui/widget/dialog/bottom_dialog.dart test/
git rm lib/ui/widget/add_folder/show_add_folder_dialog.dart
git commit -m "refactor(folder): showAddFolderDialog → showCreateFolderSheet 호출부 전환"
```

---

## Task 6: `MyLinkView` 중첩 진입점

**Files:**
- Modify: `lib/ui/view/links/my_link_view.dart`

- [ ] **Step 1: `buildChildFoldersSection` 시그니처 변경 + 렌더 조건 재구성**

`lib/ui/view/links/my_link_view.dart`의 `buildChildFoldersSection` 전체를 다음으로 교체 (현 라인 444-538):

```dart
  Widget buildChildFoldersSection(
    BuildContext context,
    List<Folder> folders,
    LinkListState state,
    Folder currentFolder,
  ) {
    if (state is! LinkListLoadedState) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (currentFolder.isClassified == false) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final children = state.childFolders;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChildFoldersHeader(context, currentFolder, children.length),
            if (children.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.w),
                child: Text(
                  '하위 폴더 없음',
                  style: TextStyle(color: grey400, fontSize: 13.sp),
                ),
              )
            else
              for (final child in children)
                InkWell(
                  onTap: () => _jumpToFolder(context, child),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.w,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: primary100,
                            borderRadius: BorderRadius.circular(10.w),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.folder,
                            size: 20.sp,
                            color: primary600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name ?? '',
                                style: TextStyle(
                                  color: blackBold,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.w),
                              Text(
                                '링크 ${addCommasFrom(child.linksTotal ?? child.links ?? 0)}개',
                                style: TextStyle(
                                  color: greyText,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: grey600,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.w),
              child: Divider(height: 1, thickness: 1.w, color: greyTab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildFoldersHeader(
    BuildContext context,
    Folder currentFolder,
    int childCount,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.w, 12.w, 8.w),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '하위 폴더 ($childCount)',
              style: TextStyle(
                color: grey600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          InkWell(
            key: const Key('my_link_view_add_child_folder'),
            onTap: () => _onAddChildFolder(context, currentFolder),
            borderRadius: BorderRadius.circular(8.w),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.create_new_folder_outlined,
                size: 18.sp,
                color: primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddChildFolder(
    BuildContext context,
    Folder parent,
  ) async {
    final newId = await showCreateFolderSheet(
      context,
      initialParentId: parent.id,
    );
    if (newId == null || !context.mounted) return;
    showBottomToast(
      context: context,
      "'${parent.name}' 아래에 폴더가 생성되었어요!",
    );
    context.read<LocalLinksFromFolderCubit>().refresh();
    context.read<LocalFoldersCubit>().getFolders();
  }
```

- [ ] **Step 2: import 추가**

`lib/ui/view/links/my_link_view.dart` 상단에 다음 import 추가:

```dart
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
```

- [ ] **Step 3: 호출부 인자 갱신**

`lib/ui/view/links/my_link_view.dart`의 `buildChildFoldersSection(context, folders, state)` 호출을 찾아 `folder` 추가:

```dart
buildChildFoldersSection(context, folders, state, folder),
```

호출 위치: `LinkView` 내부 `CustomScrollView.slivers` 중 한 줄(기존 190번 라인).

- [ ] **Step 4: analyze 확인**

Run: `fvm flutter analyze lib/ui/view/links/my_link_view.dart`
Expected: No issues found

- [ ] **Step 5: 스모크 수기 확인**

앱 실행 후 임의 폴더 상세 진입:
- 자식 없음 → `하위 폴더 (0)` + `하위 폴더 없음` + `+` 버튼 노출
- `+` 버튼 탭 → `showCreateFolderSheet` 열림 + ParentRow에 현재 폴더 경로 표시
- 이름 입력 → 생성 → 토스트 + 자식 리스트에 추가됨, **현재 폴더 상세에 그대로 머무름**
- 미분류 폴더 상세 → 섹션 전체 숨김

- [ ] **Step 6: 커밋**

```bash
git add lib/ui/view/links/my_link_view.dart
git commit -m "feat(folder): MyLinkView에 '하위 폴더 추가' 진입점 + 빈 상태 문구"
```

---

## Task 7: `showFolderOptionsDialog`에 "하위 폴더 추가"

**Files:**
- Modify: `lib/ui/widget/dialog/bottom_dialog.dart`

- [ ] **Step 1: `showFolderOptionsDialog`에 BottomListItem 추가**

`lib/ui/widget/dialog/bottom_dialog.dart`의 `showFolderOptionsDialog` 내 기존 3개 `BottomListItem` 묶음 **맨 위에** 추가:

```dart
                        BottomListItem(
                          '하위 폴더 추가',
                          callback: () async {
                            Navigator.pop(context); // 옵션 시트 먼저 닫기
                            final newId = await showCreateFolderSheet(
                              parentContext,
                              initialParentId: currFolder.id,
                            );
                            if (newId != null && parentContext.mounted) {
                              showBottomToast(
                                context: parentContext,
                                "'${currFolder.name}' 아래에 폴더가 생성되었어요!",
                              );
                              parentContext
                                  .read<LocalFoldersCubit>()
                                  .getFolders();
                              if (fromLinkView) {
                                parentContext
                                    .read<LocalLinksFromFolderCubit>()
                                    .refresh();
                              }
                            }
                          },
                        ),
```

필요 import (파일 상단에 이미 있는지 확인, 없으면 추가):

```dart
import 'package:ac_project_app/cubits/links/local_links_from_folder_cubit.dart';
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
```

- [ ] **Step 2: analyze 확인**

Run: `fvm flutter analyze lib/ui/widget/dialog/bottom_dialog.dart`
Expected: No issues found

- [ ] **Step 3: 스모크 수기 확인**

앱에서 임의 폴더 상세 진입 → 우상단 `...` 탭 → "폴더 옵션" 시트에 다음 4개 항목이 순서대로 보여야 함:
1. 하위 폴더 추가
2. 폴더명 변경
3. 폴더 이동
4. 폴더 삭제

`하위 폴더 추가` 탭 → 옵션 시트 닫히고 생성 시트 열림 → 이름 입력 → 생성 → 토스트 + 부모 상세에 자식 추가됨.

- [ ] **Step 4: 커밋**

```bash
git add lib/ui/widget/dialog/bottom_dialog.dart
git commit -m "feat(folder): 폴더 옵션 시트에 '하위 폴더 추가' 항목 추가"
```

---

## Task 8: E2E 골든 플로우

**Files:**
- Create: `integration_test/nested_folder_create_test.dart`

- [ ] **Step 1: 기존 `integration_test/login_test.dart` 구조 읽기**

Run: `sed -n '1,60p' /Users/kangmin/dev/ac_project_app/integration_test/login_test.dart`

기존 E2E의 `IntegrationTestWidgetsFlutterBinding` 초기화·앱 부팅 방식 파악.

- [ ] **Step 2: E2E 시나리오 작성**

Create `integration_test/nested_folder_create_test.dart`:

```dart
import 'package:ac_project_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('루트 폴더 생성 → 중첩 폴더 생성 → 브레드크럼 확인', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 1. 홈에서 "내 폴더" 탭 진입 (앱 네비게이션 실 경로에 맞춰 조정).
    //    실제 앱의 홈 → MyFolderPage 경로를 따라간다.
    //    (여기서 구체 제스처는 앱 빌드 상태에 따라 수정)
    final myFolderTab = find.text('내 폴더');
    if (myFolderTab.evaluate().isNotEmpty) {
      await tester.tap(myFolderTab.first);
      await tester.pumpAndSettle();
    }

    // 2. "+ 새 폴더" 탭 → 시트 열림.
    final addFolder = find.text('새 폴더');
    expect(addFolder, findsAtLeastNWidgets(1));
    await tester.tap(addFolder.first);
    await tester.pumpAndSettle();

    // 3. 이름 입력 → 생성.
    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      '개발',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 4. `개발` 폴더가 그리드에 보이고 해당 폴더 상세로 이동했는지 확인.
    expect(find.text('개발'), findsWidgets);

    // 5. "하위 폴더 (0)" 섹션의 + 버튼 탭.
    final addChild = find.byKey(const Key('my_link_view_add_child_folder'));
    if (addChild.evaluate().isEmpty) {
      // 이미 `개발` 상세에 있지 않다면 진입.
      await tester.tap(find.text('개발').first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('my_link_view_add_child_folder')));
    await tester.pumpAndSettle();

    // 6. 시트에서 "React" 입력 → 생성.
    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'React',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 7. 현재 `개발` 상세에 머무른 채 "하위 폴더 (1)" + React 표시.
    expect(find.text('하위 폴더 (1)'), findsOneWidget);
    expect(find.text('React'), findsOneWidget);

    // 8. React 진입 → 브레드크럼 확인.
    await tester.tap(find.text('React'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('개발'), findsWidgets); // 브레드크럼에 개발 노출
    expect(find.text('React'), findsWidgets); // 타이틀
  });
}
```

**주의**: 앱의 네비게이션 플로우는 홈 → 탭 → `MyFolderPage`로 이어지는 실제 경로와 다를 수 있다. Step 1에서 본 기존 `login_test.dart`의 네비게이션 패턴을 따라 조정한다. 위 시나리오는 뼈대이며, 실행 시 find 실패하는 항목을 실제 UI 텍스트로 교체해야 한다.

- [ ] **Step 3: E2E 실행 (로컬 시뮬레이터/실기기)**

Run: `fvm flutter test integration_test/nested_folder_create_test.dart`
Expected: PASS (필요 시 `find` 텍스트 조정)

- [ ] **Step 4: CI 파이프라인 포함 여부 확인**

Run: `ls /Users/kangmin/dev/ac_project_app/.github /Users/kangmin/dev/ac_project_app/Makefile 2>/dev/null && cat /Users/kangmin/dev/ac_project_app/Makefile 2>/dev/null | head -40`

integration_test 실행 타겟이 있는지 확인. 없으면 이 플로우는 로컬 수동 실행으로 남기고 Makefile/CI 추가는 **이번 계획 범위 외**로 처리한다.

- [ ] **Step 5: 커밋**

```bash
git add integration_test/nested_folder_create_test.dart
git commit -m "test(folder): 중첩 폴더 생성 E2E 골든 플로우"
```

---

## Task 9: Pro 동기화 수동 체크리스트 + 최종 검증

이 Task는 코드 변경 없음. 릴리스 전 수동 검증 게이트.

- [ ] **Step 1: Pro 계정 로그인 (실기기)**

Pro 계정으로 로그인 후 Supabase Studio를 열어 `folders` 테이블을 관찰한다.

- [ ] **Step 2: 루트 폴더 생성 → 원격 확인**

앱에서 루트 폴더 `A` 생성.
Supabase Studio에서 `select * from folders where name = 'A' order by created_at desc limit 1` 실행.
**기대**: `client_id=<로컬 A.id>`, `parent_id=null`, `is_classified=true`.

- [ ] **Step 3: 중첩 폴더 생성 → parent_id 왕복 확인**

앱에서 `A` 진입 → `+ 하위 폴더` → `B` 생성.
Supabase Studio에서 B 레코드의 `parent_id`가 `A의 uuid`와 일치하는지 확인.

- [ ] **Step 4: 오프라인 → 온라인 복귀 시나리오**

비행기 모드 on → `B` 아래 `C` 생성 → 비행기 모드 off.
`dirty=true` 마킹 상태로 자동 보정 타이밍을 기다린 후(또는 앱 재시작 후) Supabase에 `C`가 `parent_id=B의 uuid`로 업서트됐는지 확인.

- [ ] **Step 5: 고아 부모 시나리오**

Supabase Studio에서 `A` 레코드를 **원격에서 직접 삭제**.
앱에서 여전히 `A` 아래 `D` 생성(로컬은 A가 아직 살아 있음).
**기대**: 로컬 D 존재, 원격 D 없음, `dirty=true` 유지.
수동 "전체 백업" 버튼 또는 머지 트리거 후 D가 원격에 복원되는지 확인.

- [ ] **Step 6: 전체 테스트 + 정적 분석**

```bash
fvm flutter analyze
fvm flutter test
```

Expected: 둘 다 clean.

- [ ] **Step 7: 스펙의 Verification 체크리스트 전부 체크**

`docs/superpowers/specs/2026-04-23-nested-folder-create-design.md`의 "Verification 체크리스트" 섹션 7개 항목을 순서대로 확인하고 체크박스 채움.

- [ ] **Step 8: PR 생성 + 릴리스 노트 작성**

Phase 1 완료를 알리는 PR 기술 — 다음 내용 포함:
- 스펙 링크
- T8 수기 체크리스트 결과 캡처
- Phase 2(Chrome 확장)는 별도 스펙으로 후속

---

## 전체 종료 기준 체크리스트

- [ ] Task 1~8 모두 커밋됨
- [ ] `fvm flutter analyze` clean
- [ ] `fvm flutter test` 전부 PASS
- [ ] Task 9의 수동 체크리스트 완주 (Pro 실기기 1회)
- [ ] 3개 진입점에서 생성 성공 수기 확인:
  - [ ] `MyFolderPage` 루트 "+"
  - [ ] `MyLinkView` 하위 폴더 섹션 "+"
  - [ ] `showFolderOptionsDialog` "하위 폴더 추가"
- [ ] 공유/업로드 플로우 루트 생성 회귀 없음 수기 확인

---

## 후속 작업 메모 (Phase 1 종료 후)

1. **`folder_name_cubit.dart` 완전 폐기** — rename 다이얼로그에서도 `FolderNameCubit` 사용 중. rename도 `showCreateFolderSheet`와 유사한 dumb 시트 패턴으로 정리하면 `FolderNameCubit`/`ButtonStateCubit` 모두 폐기 가능. 별도 리팩터링 스펙으로.
2. **`pick_folder_sheet`의 실시간 구조 반영** — 현재 스냅샷 기반. 필요 시 별도 스펙.
3. **Phase 2 — Chrome 확장** — Phase 1 UX 학습 반영 후 별도 계획서(`2026-MM-DD-nested-folder-create-extension-plan.md`) 작성.
