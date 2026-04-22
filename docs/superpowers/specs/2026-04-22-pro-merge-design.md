# Pro 로그인 자동 머지 (로컬 ↔ 원격) 설계

- 작성일: 2026-04-22
- 작성자: Claude + 사용자 브레인스토밍
- 상태: 구현 완료 (2026-04-22, 수동 검증 대기)
- 구현 커밋 범위: `203ddf15..415085e2` (develop 브랜치)

## 배경

Pro 유저는 여러 기기(모바일 앱, 크롬 확장 프로그램)에서 같은 Supabase 계정으로 링크를 수집한다. 현재 `SyncRepository`는 "full replace" 방식의 백업(`backupToRemote`)과 복구(`restoreFromRemote`)만 제공한다. 이 때문에 다음 케이스에서 데이터 병합이 불가능하다.

- 로컬(모바일)에도 링크가 있고, 원격(크롬 확장이 쌓은 북마크)에도 링크가 있는 상태에서 Pro 로그인한 경우
- 현재 `HomeView._maybeAutoRestore`는 "로컬 비어있음 + 원격 있음"일 때만 자동 복구함. 로컬이 비어있지 않으면 아무 동작도 하지 않음. 수동 백업/복원 버튼은 full replace라 반대편 데이터가 사라짐.

본 문서는 양쪽 데이터를 합치는 자동 머지 동작을 정의한다.

## 결정 요약

- **중복 판단**: `같은 URL + 같은 폴더 경로`면 중복(브레인스토밍 Q1=C)
- **폴더 매칭 키**: 루트부터 이름 체인으로 만든 `path_key`. 이름은 byte-wise 동일할 때만 같음(Q2=B, Q7=A). `is_classified=false`(미분류)는 path_key 무시하고 무조건 하나로 통합
- **필드 머지 규칙**: 비어있지 않은 쪽 우선, 둘 다 있으면 `updated_at` 최신, `created_at`은 더 이른 쪽, `updated_at`은 머지 시점(Q3=B)
- **트리거**: 자동. HomeView의 `isPro` 전환 시점에 `_maybeAutoSync`가 조건 없이 머지 함수 호출(Q4=A)
- **실패 정책**: 로컬은 SQLite 트랜잭션으로 원자적. 원격은 best-effort + `lp_remote_dirty` 플래그 기반 보정 백업에 위임(Q5=B)
- **단일화 범위**: 머지 함수 하나가 4가지 케이스(로컬/원격 각각 존재/비어있음)를 모두 흡수. `backupToRemote`/`restoreFromRemote`는 수동 경로와 dirty 보정용으로 계속 유지(Q6=C)

## 섹션 1: 머지 트리거

- `HomeView._maybeAutoRestore` → `_maybeAutoSync`로 이름 변경 및 조건 단순화
- 조건: `isPro == true && _autoSyncAttempted == false`
  - `localEmpty` / `hasRemoteBackup` 사전 체크 제거. 머지 함수가 내부적으로 모든 케이스 처리
- 성공 여부와 무관하게 `_autoSyncAttempted = true` (무한 재시도 방지). 원격 실패는 dirty 보정 루틴이 이후 처리
- 호출 경로: `BlocListener<AuthCubit>`에서 `isPro` 전환 감지 시 → `_maybeAutoSync(ctx)`

## 섹션 2: 머지 알고리즘 (순수 계산)

### 입력

```dart
MergeResult computeMerge({
  required List<LocalFolder> localFolders,
  required List<LocalLink> localLinks,
  required List<Map<String, dynamic>> remoteFolders,
  required List<Map<String, dynamic>> remoteLinks,
  required DateTime mergeAt,
});
```

원격 행은 Supabase `from('folders').select()` / `from('links').select()` 결과 그대로. 변환은 `computeMerge` 내부에서 수행.

### 1단계: path_key 생성

- 각 폴더에 대해 "루트부터 현재까지 이름 체인"을 **NULL 문자(Dart 리터럴 `'\x00'`)** 구분자로 join
  - 구분자 선택 이유: 사용자가 폴더 이름에 입력할 수 없는 제어문자라서, `/`나 ` ` 같은 일반 문자를 쓸 때 생기는 모호성이 없음 (예: `A/B` 이름 폴더와 `A` 아래 `B` 계층 충돌 방지)
  - 예: 루트 `Work` 아래 `Frontend` 폴더 → path_key = `"Work"` + `'\x00'` + `"Frontend"`
- 미분류 폴더(`is_classified=false`)는 path_key 대신 고정 키 `"__UNCLASSIFIED__"` 사용
  - 양쪽 미분류가 하나로 통합됨
- path_key 계산은 parent_id 체인을 따라가는 재귀 함수. 원격 폴더는 parent_id가 UUID이므로 `remote_id → remote_folder` 인덱스를 먼저 구성한 뒤 계산

### 2단계: 폴더 머지

- 로컬 폴더는 `local_folder.id` → path_key 맵 생성
- 원격 폴더는 `remote_folder.client_id` → path_key 맵 생성
- path_key 기준으로 그룹핑:
  - 양쪽 그룹 → 필드 머지 규칙 적용:
    - `name`: path_key가 같다는 건 이미 동일 → 로컬 값 사용
    - `thumbnail`: 비어있지 않은 쪽 우선, 둘 다 있으면 updated_at 최신
    - `is_classified`: OR (둘 중 하나라도 true면 true)
    - `created_at`: 둘 중 더 이른 쪽
    - `updated_at`: `mergeAt`
  - 한쪽만 있는 그룹 → 그대로 채택 (updated_at 원본 유지)
- 각 머지된 폴더에 새 `client_id` 할당 (1부터 순차)
  - 매핑 맵 구축:
    - `localOldIdToNewId: Map<int, int>` (로컬 원본 id → 새 client_id)
    - `remoteOldClientIdToNewId: Map<int, int>` (원격 client_id → 새 client_id)
    - `pathKeyToNewId: Map<String, int>` (편의용)

### 3단계: parent_id 복원

- 각 머지된 폴더에 대해:
  - path_key 체인의 바로 앞 구간을 잘라 부모 path_key 계산
    - 예: `"Work" + '\x00' + "Frontend"` → 부모 path_key = `"Work"`
    - 최상위면 부모 없음
  - 부모 path_key가 `pathKeyToNewId`에 있으면 그 id를 `parent_id`로 세팅
  - 미분류는 항상 최상위 → parent_id = null
- 부모 충돌은 구조적으로 발생하지 않음 (같은 path_key면 부모 path_key도 같음)

### 4단계: 링크 머지

- 링크 키: `(url, 소속 폴더의 path_key)`
  - URL은 정규화 없이 그대로 (byte-wise 비교)
  - 폴더 매핑: 로컬은 `local_folder_id → path_key`, 원격은 `folder_uuid → path_key`
- 같은 키 그룹 → 필드 머지:
  - `title`, `image`, `describe`, `inflow_type`: 비어있지 않은 쪽 우선, 둘 다 있으면 updated_at 최신
  - `url`: 로컬 원본
  - `folder_id`: `pathKeyToNewId[해당 path_key]`
  - `created_at`: 더 이른 쪽
  - `updated_at`: `mergeAt`
- 한쪽만 있는 키 그룹 → 그대로 채택 (folder_id는 새 id로 매핑)
- 링크도 새 `client_id` 재할당 (1부터 순차)

### 5단계: 결과

```dart
class MergeResult {
  final List<LocalFolder> folders; // 새 id, parent_id 매핑 완료
  final List<LocalLink> links;     // 새 id, folder_id 매핑 완료
  final MergeStats stats;
}

class MergeStats {
  final int foldersMerged;    // 양쪽 모두에서 매칭된 폴더 수
  final int foldersLocalOnly;
  final int foldersRemoteOnly;
  final int linksMerged;
  final int linksLocalOnly;
  final int linksRemoteOnly;
}
```

## 섹션 3: 머지 쓰기 단계

### 1) 로컬 SQLite 트랜잭션 교체

```dart
final db = await _databaseHelper.database;
await db.transaction((txn) async {
  await txn.delete('link');
  await txn.delete('folder');

  // folders 전체 insert (parent_id 없이)
  for (final f in result.folders) {
    await txn.insert('folder', { ...parent_id 제외... });
  }

  // parent_id 2-pass update (자기 참조 FK 회피)
  for (final f in result.folders) {
    if (f.parentId != null) {
      await txn.update('folder', {'parent_id': f.parentId},
          where: 'id = ?', whereArgs: [f.id]);
    }
  }

  for (final l in result.links) {
    await txn.insert('link', l.toMap());
  }

  // sqlite_sequence 보정
  await txn.rawUpdate(
    "UPDATE sqlite_sequence SET seq = (SELECT COALESCE(MAX(id), 0) FROM folder) WHERE name = 'folder'");
  await txn.rawUpdate(
    "UPDATE sqlite_sequence SET seq = (SELECT COALESCE(MAX(id), 0) FROM link) WHERE name = 'link'");
});
```

실패 시 SQLite가 전체 롤백 → 로컬은 머지 전 상태. 예외를 상위로 throw하여 호출자가 "머지 전체 실패"로 인지.

### 2) 원격 full replace (best-effort + dirty)

로컬이 이미 머지 결과로 교체되어 있으므로, **기존 `backupToRemote()` 함수 재사용**:

```dart
final ok = await backupToRemote();
if (!ok) {
  // 로그만 남김. dirty=true는 remoteWrite 패턴이 이미 설정.
  Log.e('mergeWithRemote: remote replace failed, will be corrected by dirty sync');
}
```

`backupToRemote`는 내부적으로 `_setDirty(true)` → 작업 → 성공 시 `_setDirty(false)`. 원격 실패 시 dirty=true가 유지되고, 다음 포그라운드 복귀 시 `HomeView._maybeRunDirtyCorrectionBackup`이 다시 `backupToRemote` 호출하여 수렴.

### 3) 1회성 플래그

- `HomeView._autoSyncAttempted = true`
- 원격 실패해도 true 유지 (재시도는 dirty 보정이 담당)
- 앱 재시작 시 false로 리셋 (인스턴스 변수)

## 섹션 4: 실패/재시도 경로

| 상황 | 로컬 | 원격 | 사용자 체감 | 추가 조치 |
|---|---|---|---|---|
| 정상 머지 성공 | 머지 결과 | 머지 결과 | 링크 목록에 합쳐진 결과 | 없음 |
| 머지 계산 중 예외 | 머지 전 | 머지 전 | 변화 없음 | 로그 남김. 다음 실행에서 재시도 |
| 로컬 트랜잭션 실패 | 머지 전 | 머지 전 | 변화 없음 | `_autoSyncAttempted=true` 유지하여 반복 시도로 인한 부하 방지. 사용자가 앱 재시작하면 다시 시도 |
| 원격 적용 실패 | 머지 결과 | 머지 전 | 로컬에서는 합쳐져 보임 | dirty=true 유지. 포그라운드 복귀 시 보정 백업이 원격 수렴 |

예외 처리는 `mergeWithRemote()` 최상단에서 try/catch로 감싸 dirty 플래그를 잘못 건드리지 않도록 주의 (dirty는 `backupToRemote` 내부 `remoteWrite`가 관리).

## 섹션 5: 공개 API와 기존 함수 관계

### 신규

```dart
class SyncRepository {
  /// 로컬 + 원격 머지. 순수 계산 → 로컬 원자적 교체 → 원격 full replace.
  /// 반환: 성공 시 MergeResult, 실패 시 null
  Future<MergeResult?> mergeWithRemote();

  @visibleForTesting
  MergeResult computeMerge({...});
}
```

### 기존 함수 유지 여부

| 함수 | 유지 | 호출 경로 |
|---|---|---|
| `backupToRemote()` | O | 수동 백업 버튼, dirty 보정, `mergeWithRemote` 내부 재사용 |
| `restoreFromRemote()` | O | 수동 복구 버튼 |
| `hasRemoteBackup()` | O (호출자 줄어듦) | 수동 복구 경로에서만 사용. `_maybeAutoSync`는 호출 안 함 |
| `purgeRemote()` | O | Pro → Free 전환 시 |
| `upsertFolderRemote`, `upsertLinkRemote`, `deleteFolderRemote`, `deleteLinkRemote` | O | 일상 CRUD 원격 쓰기 |

### HomeView 변경

| 함수 | 변경 |
|---|---|
| `_maybeAutoRestore` → `_maybeAutoSync` | 내부에서 `sync.mergeWithRemote()` 호출. `localEmpty`/`hasRemoteBackup` 사전 체크 제거. `_autoRestoreAttempted` → `_autoSyncAttempted`로 이름 변경 |
| `BlocListener<AuthCubit>` 콜백 | 호출 함수 이름만 교체 |

## 섹션 6: 테스트 전략

### 단위 테스트 — 순수 계산 (`test/provider/sync/merge_compute_test.dart`)

- 빈 로컬 + 빈 원격 → 빈 결과
- 빈 로컬 + 원격만 있음 → 원격 전체 채택 (folder/link 수, client_id 재번호 확인)
- 로컬만 있음 + 빈 원격 → 로컬 전체 채택
- 양쪽 동일 URL + 동일 path_key → 하나로 머지 (필드 규칙 검증)
- 양쪽 동일 URL + 다른 path_key → 두 개로 유지 (Q1=C 검증)
- 양쪽 같은 이름 다른 경로(`Work/Frontend` vs `Dev/Frontend`) → 두 개로 유지 (Q2=B 검증)
- 대소문자 다른 폴더/URL → 두 개로 유지 (Q7=A 검증)
- 양쪽 미분류 폴더 → 하나로 통합
- 필드별 머지: null vs value / "" vs value / 둘 다 value + updated_at 비교
- parent_id 체인: 3단계 이상 중첩된 폴더 매칭 후 parent_id 재매핑 정확성
- client_id 재번호 후 folder_id 매핑 일관성

### 통합 테스트 (`test/provider/sync/merge_with_remote_test.dart`)

- `sqflite_common_ffi`로 실제 DB, Supabase는 mock
- 로컬 트랜잭션 성공 + 원격 성공 → 양쪽 일치
- 로컬 성공 + 원격 실패 시뮬레이션 → 로컬만 반영, dirty=true
- 로컬 실패 시뮬레이션 → 양쪽 변경 없음
- 머지 후 sqlite_sequence 보정 확인
- 머지 후 `RecentFoldersRepository.getRecentIds()` 비어있음 확인
- 머지 후 `share.db` 폴더 이름 목록 일치 확인

### 회귀 테스트

- 기존 `backupToRemote` / `restoreFromRemote` / `purgeRemote` 테스트 전부 통과

## 섹션 7: 마이그레이션 & 배포 고려사항

### 기존 Pro 유저 영향

- 앱 업데이트 후 HomeView 첫 진입 시 자동 머지 1회 실행
- 로컬과 원격이 이미 동일한 상태라도 **client_id가 전부 재번호**됨 (1부터 순차)
- 영향 범위: 섹션 8 참조

### 크롬 확장과의 규칙 일치

- 이번 범위 밖. 크롬 확장에서 동일한 규칙(path_key, 필드 머지)을 쓰지 않으면 다음 머지에서 또 중복 생성 가능
- 본 문서 범위는 모바일 앱 측 머지만. 크롬 확장 동기화는 별도 스펙으로 추후 작성

### 롤백 가능성

- 머지 실행이 로컬 상태를 새로 쓰므로 되돌리기 불가
- Q4=A로 "자동 우선 정책" 선택한 결과. 안전장치(사전 스냅샷 등)는 이번 범위 제외

## 섹션 8: 영향 범위 요약

| 영역 | 영향 | 조치 |
|---|---|---|
| `RecentFoldersRepository` (SharedPref `lp_recent_folder_ids`) | 저장된 ID 무효화 | 머지 성공 직후 `clear()` 호출 |
| `share.db` (native 공유 시트 폴더 목록) | name 기반이라 id 무관 | 머지 성공 직후 `ShareDataProvider.syncFoldersToShareDB()` 호출 |
| iOS Share Extension `selectedFolder` | 런타임 변수 | 조치 불필요 |
| Navigator `folderDrillDown` args | 런타임만 사용. 머지 타이밍상 드릴다운 열려있을 수 없음 | 조치 불필요 |
| `PickFolderSheet`의 `byId[id]` 조회 | null이면 조용히 필터링 | clear로 정리되므로 조치 불필요 |
| `ProRemoteHooks` 개별 원격 쓰기 | 머지 중에는 호출 안 됨 | 조치 불필요 |
| 현재 메모리의 cubit 상태 (`LocalFoldersCubit` 등) | 머지 후 `getFolders` 재호출 필요 | `_maybeAutoSync` 성공 경로에서 `ctx.read<LocalFoldersCubit>().getFolders()` 호출 |

### 머지 성공 후 후처리 체크리스트

```dart
// SyncRepository.mergeWithRemote 또는 HomeView._maybeAutoSync 성공 경로에서:
await const RecentFoldersRepository().clear();
await ShareDataProvider.syncFoldersToShareDB();
ctx.read<LocalFoldersCubit>().getFolders();
```

각 후처리 함수가 예외를 throw할 수 있으므로 각각 try/catch로 로그만 남김 (머지 본체는 이미 성공).

## 향후 과제 (이번 범위 밖)

- 크롬 확장 측 동일 규칙 적용
- 머지 결과 안내 UI (toast 또는 스낵바로 "N개 폴더, M개 링크가 기기 간에 병합됐습니다")
- URL 정규화 옵션 (trailing slash, query param 제거 등 크롬↔앱 중복 감소용)
- 머지 스냅샷 기반 undo
