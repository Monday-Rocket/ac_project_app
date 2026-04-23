# 중첩 폴더 생성 기능 설계 스펙

**작성일**: 2026-04-23
**대상**: 링크풀 Flutter 앱(`ac_project_app`) + Chrome 확장(`linkpool-chrome-extension`)
**목표**: 앱과 확장 모두에 "특정 폴더 아래에 새 폴더를 만드는" 쓰기 경로를 추가한다. 읽기/이동은 이미 완성되어 있다.

## 배경

| 플랫폼 | 모델/저장소 | 읽기 UI | 이동 | 생성(기존) |
|---|---|---|---|---|
| 앱 | `LocalFolder.parentId` + `LocalFolderRepository`의 `getChildFolders`/`getAllDescendants`/`getBreadcrumb`/`getRecursiveLinkCounts` 완비 | `MyLinkView` 하위 폴더 섹션 + 브레드크럼, `folder_tree_modal`, `pick_folder_sheet` | `moveFolder` API + `showFolderOptionsDialog`의 "폴더 이동" | **루트 전용**. `showAddFolderDialog`/`FolderNameCubit`/`LocalFoldersCubit.createFolder`는 parent를 받지 않음. |
| 확장 | `storage.createFolder(name, parentId, bookmarkId)` 이미 parentId 수용 | `FolderTree`/`FolderTreeItem` | — | **수동 생성 UI 없음**. 북마크 동기화가 유일한 폴더 진입점. |

중첩 구조로 부모 변경 경로(`moveFolder`)는 존재하지만, **직접 "부모 아래 생성"이 막혀 있어** 중첩 폴더를 의도적으로 설계할 수 없다.

## 범위

- **Phase 1 — 앱**: Pro 동기화 버그 수정 → Repository 보강 → Cubit 시그니처 확장 → `showCreateFolderSheet` 신규 → 진입점 연결 → 구 다이얼로그 폐기.
- **Phase 2 — 확장**: Phase 1 종료 시 재확정. 트리 내 루트 "+" 버튼과 행 호버 "+"를 통한 생성 UI.

각 Phase는 독립 릴리스 단위.

## 합의된 결정사항

| 항목 | 결정 | 근거 질문 |
|---|---|---|
| 대상 플랫폼 | 앱 + 확장, 앱 먼저 | Q1 |
| 앱 생성 진입점 | **(A) `MyLinkView`** 하위 폴더 섹션 "+" / `...` 옵션 "하위 폴더 추가" + **(B) 루트 "+"** 시트에 "상위 폴더 (선택)" 행. 공유/업로드 플로우는 루트 고정. | Q2 |
| 깊이 제한 | **무제한**. 기존 "자기 후손 이동 금지"만 유지 | Q3 |
| 이름 중복 범위 | **형제 범위만 금지**. 경로가 다르면 동명 허용 | Q4 |
| Pro 동기화 | **명시적 검증 항목**으로 포함. `upsertFolderRemote`에 숨은 버그(`parent_id: null` 고정) 확인됨 | Q5 |
| Pro 동기화 수정 방식 | **2-pass** (`_resolveRemoteFolderId` 해결 후 upsert, 부모 미해결 시 `dirty=true` + 조기 반환) — 링크 업서트와 동일 패턴 | Q6 |
| 기존 다이얼로그 개조 수위 | **전면 개조(옵션 C)** — `showAddFolderDialog`/`FolderNameCubit` 폐기하고 `showCreateFolderSheet` 신규 | 사용자 지시 |
| ParentRow 위치 | TextField **위** | Q-A1 |
| 빈 "하위 폴더" 섹션 | 헤더 유지 + "하위 폴더 없음" 문구 + "+" 노출 | Q-B1 |
| 시트 제목 | 루트/중첩 공통 **"새로운 폴더"** | Q-C1 |

## 아키텍처

Phase 1에서 건드리는 레이어:

```
[UI]
  showCreateFolderSheet (신규)     · 이름 + 상위 폴더 선택 + 완료. dumb 위젯.
  showAddFolderDialog (폐기)
  bottom_dialog.dart              · saveEmptyFolder, runCallback 제거, 옵션 시트에 "하위 폴더 추가" 추가
  MyLinkView                      · "하위 폴더 (N)" 헤더 "+" + _onAddChildFolder 헬퍼
  MyFolderPage 루트 "+"            · showCreateFolderSheet(initialParentId: null)
  folder_add_title.dart           · showCreateFolderSheet(initialParentId: null, allowParentPick: false)

[Cubit]
  FolderNameCubit (폐기)
  LocalFoldersCubit.createFolder(name, {int? parentId})  · parentId named optional 추가

[Repository]
  LocalFolderRepository.createFolder(folder)             · 기존 (parentId 이미 지원)
  LocalFolderRepository.isSiblingNameTaken(parentId, name) · 신규
  LocalFolderRepository.createFolder에 "부모 존재 확인" 가드 추가

[Sync]
  SyncRepository.upsertFolderRemote                      · parent_id: null 고정 제거, 2-pass 적용
  SyncRepository.upsertLinkRemote                        · _resolveRemoteFolderId 예외 try/catch (동일 일관성)
```

Phase 2에서 건드리는 레이어:

```
[UI]
  FolderTree / FolderTreeItem      · 루트 "+ 새 폴더" 버튼 + 행 호버 "+"
  (신규) CreateFolderDialog.tsx 또는 인라인 input (Phase 2 시작 시 결정)

[Hook]
  useFolderTree                    · createFolder(name, parentId) 노출

[Storage]
  storage.createFolder             · 변경 없음
```

건드리지 않는 것: `merge_compute.dart`, `backupToRemote` (이미 parent_id 왕복 완성), 중첩 읽기 UI 전반, 원격 스키마.

## 디자인 언어 (앱 스캔 결과)

### 팔레트
- **Primary**: `primary600 #804DFF`(메인 액션) / `primary800 #701FFF`(포커스 선) / `primary100 #F6F7FE`(연한 배경)
- **Disabled**: `secondary #C8BFFF` (primary 저채도) / `grey300 #CFD4DE` (텍스트)
- **Text**: `grey800 #30343E`(제목) / `blackBold #13181E`(강조) / `grey600 #606873`(보조) / `greyText #62666C`(메타) / `grey400 #B0B8C1`(힌트)
- **Surface**: `white`(시트 배경) / `grey100 #F5F7FA`(검색/브레드크럼) / `greyTab #ECEDEE`(얇은 구분선)
- **Error**: `redError #F4406B`

### 타이포 (`flutter_screenutil`의 `.sp`)

| 용도 | 크기 | 굵기 | 색 |
|---|---|---|---|
| 시트 제목 | `20.sp` | bold | 기본 black |
| 주 버튼 텍스트 | `17.sp` | bold | white |
| 완료 텍스트(우상단) | `16.sp` | w500 | `grey800` / `grey300`(disabled) |
| TextField 입력 | `18.sp` | w500 | `grey800` |
| TextField 힌트 | `17.sp` | w500 | `grey400` |
| 본문 폴더명 | `15.sp` | w600 | `blackBold` |
| 리스트 서브라벨 | `11~12.sp` | w500~w600 | `grey600` / `greyText` |

### 레이아웃 (`.w`, 24 수평 기준)
- 시트 가로 여백 24.w / 상단 30.w / 하단 iOS 16.w, Android `MediaQuery.padding.bottom`
- 시트 상단 모서리 `topLeft/topRight: 20.w`
- 주 버튼 위 여백 40~50.w, 높이 55.w, 모서리 `circular(12.w)`
- 구분선 `Divider(height:1, thickness:1.w, color: greyTab)`
- 리스트 아이템 패딩 `vertical 10~12.w / horizontal 16~24.w`

### 컴포넌트 어법
- 주요 선택자는 `showModalBottomSheet` + 상단 20.w 라운드
- "완료" 버튼은 이중(우상단 텍스트 + 하단 보라 큰 버튼) — 신규 시트도 동일 패턴 유지
- 입력 필드 `UnderlineInputBorder` 2.w, enabled=`greyTab`, focused=`primary800`, error=`redError`, `autofocus: true`
- 폴더 아이콘: 분류=`primary600`, 미분류=`grey600`
- 생성 액션 아이콘: `Icons.create_new_folder_outlined`
- 토스트: `showBottomToast`

### 복사 톤
- 제목: `"새로운 폴더"`, `"폴더명 변경"`, `"폴더 옵션"` — 명사형
- 액션: `"완료"`, `"폴더 생성하기"` — `~하기` 톤
- 에러: `"…예요. …해주세요."` 형식
- 성공 토스트: `"…생성되었어요!"` 형식, 느낌표 포함

## 컴포넌트 상세 (Phase 1)

### 신규: `lib/ui/widget/folder/show_create_folder_sheet.dart`

```dart
/// 루트 또는 특정 부모 아래에 새 폴더를 만드는 바텀 시트.
/// 취소=null, 생성 성공=새 폴더 id.
Future<int?> showCreateFolderSheet(
  BuildContext context, {
  int? initialParentId,         // 기본 부모 (null=루트)
  bool allowParentPick = true,  // false면 상위 폴더 행 숨김 + 고정
});
```

**로컬 상태 (StatefulWidget, Cubit 의존 없음)**:

| 필드 | 타입 | 초기값 |
|---|---|---|
| `_parentId` | `int?` | `initialParentId` |
| `_parentPath` | `String` | `"루트"` 또는 `getBreadcrumb(initialParentId)` 조인 |
| `_nameController` | `TextEditingController` | `""` |
| `_errorText` | `String?` | `null` |
| `_submitting` | `bool` | `false` |

**내부 구조**:

```
[시트 상단 모서리 20.w, 배경 white]
 Padding(top:30.w, h:24.w, bottom: viewInsets + 16.w)
   ├─ Stack
   │    ├─ Center("새로운 폴더", 20.sp bold)
   │    └─ Align.topRight("완료", 16.sp w500, grey800/grey300)
   ├─ SizedBox(28.w)
   ├─ ParentRow (allowParentPick=true일 때만 렌더)
   │    InkWell onTap → showPickFolderSheet(includeUnclassified: false)
   │    Icon(folder, 16.sp, primary600)
   │    "상위 폴더" (13.sp w500 grey600)
   │    _parentPath (14.sp w500 blackBold, overflow ellipsis 앞쪽 자름)
   │    Icon(chevron_right, 18.sp, grey600)
   │    하단 1.w greyTab 구분선
   ├─ SizedBox(20.w)
   ├─ Form + TextFormField(autofocus, UnderlineInputBorder, hint "새로운 폴더 이름")
   │    · validator: 20자 초과만 inline 에러 (onChange 단계)
   │    · 비어있음/공백/중복/부모없음은 submit 단계에서 `_errorText`로 주입
   └─ SizedBox(40.w) + ElevatedButton "폴더 생성하기"
        · 55.w, primary600, disabled=secondary, 17.sp bold white, radius 12.w
        · _submitting 중이면 스피너(20.w, white)로 교체
```

**주요 콜백**:
- `_onParentTap()` → `showPickFolderSheet` → 반환된 id로 `_parentId`, `_parentPath` 갱신. `_errorText` 초기화 (다른 부모 아래에서는 같은 이름 허용 가능).
- `_onSubmit()`:
  1. `name = _nameController.text.trim()`
  2. 비어있음 → `_errorText = "폴더 이름을 입력해주세요."`, 종료
  3. `_submitting=true`
  4. `LocalFoldersCubit.createFolder(name, parentId: _parentId)` 결과를 `CreateFolderResult` sealed 타입으로 수신:
     - `Created(id)` → `Navigator.pop(context, id)`
     - `DuplicateSibling` → `_errorText = "같은 위치에 이미 같은 이름의 폴더가 있어요. 다른 이름을 입력해주세요."`
     - `ParentMissing` → `_errorText = "상위 폴더를 찾을 수 없어요. 다시 선택해주세요."`
     - `Failed` → `_errorText = "폴더를 만들지 못했어요. 잠시 후 다시 시도해주세요."`
  5. 어느 실패 경로든 `_submitting=false`로 복귀

**버튼 활성화 규칙**:
- 이름이 비어있지 않고 `_submitting=false`이고 `_errorText=null`일 때 enable.
- 우상단 "완료" 텍스트와 하단 버튼 둘 다 동일 규칙.

**키보드**: `KeyboardDismissOnTap` 감쌈, `Padding.bottom = MediaQuery.viewInsets.bottom + 16.w`.

### 수정: `lib/cubits/folders/local_folders_cubit.dart`

신규 sealed 결과 타입(파일 상단 or 별도 파일):

```dart
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
class Failed extends CreateFolderResult {
  const Failed(this.error);
  final Object error;
}
```

```dart
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
    // Repository가 "부모 폴더가 존재하지 않습니다." 또는 미분류 관련 에러
    Log.e('LocalFoldersCubit.createFolder state error: $e');
    if (e.message.contains('부모 폴더')) return const ParentMissing();
    return Failed(e);
  } catch (e) {
    Log.e('LocalFoldersCubit.createFolder error: $e');
    return Failed(e);
  }
}
```

하위 호환: 기존 호출부는 반환값을 확인하지 않았으므로, 시그니처 변경에 맞춰 호출부도 **이번 스펙의 5단계에서 함께 업데이트**됨 (구 `createFolder('name')` 호출은 전환 대상).

### 수정: `lib/provider/local/local_folder_repository.dart`

```dart
/// 같은 부모 아래에 동일한 이름의 폴더가 이미 있는지.
/// parentId=null은 루트 범위.
/// 비교는 바이트-equal (대소문자 구분, 유니코드 정규화 없음).
Future<bool> isSiblingNameTaken(int? parentId, String name) async {
  final db = await _databaseHelper.database;
  final rows = parentId == null
      ? await db.query(_table,
          where: 'parent_id IS NULL AND name = ?',
          whereArgs: [name], limit: 1)
      : await db.query(_table,
          where: 'parent_id = ? AND name = ?',
          whereArgs: [parentId, name], limit: 1);
  return rows.isNotEmpty;
}
```

**`createFolder`에 추가 가드**:
- `folder.parentId != null`일 때 `getFolderById(parentId)`로 존재 확인. 없으면 `StateError('부모 폴더가 존재하지 않습니다.')` throw (E2).
- 기존 `_assertNotUnclassified`는 유지.
- Repository 레벨에서도 `isSiblingNameTaken`을 호출해 DB 무결성 방어선 이중화.

### 수정: `lib/provider/sync/sync_repository.dart`

`upsertFolderRemote`를 2-pass로 변경:

```dart
Future<void> upsertFolderRemote(LocalFolder folder) async {
  final userId = _requireUserId();
  if (userId == null || folder.id == null) return;

  String? parentServerId;
  if (folder.parentId != null) {
    try {
      parentServerId = await _resolveRemoteFolderId(userId, folder.parentId!);
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

`upsertLinkRemote`의 `_resolveRemoteFolderId` 호출도 동일하게 try/catch로 감싸고 예외 시 `dirty=true` + 조기 반환 (Known adjacent work를 1단계에 승격).

### 수정: `lib/ui/view/links/my_link_view.dart`

`buildChildFoldersSection`을 확장:
- 시그니처에 `currentFolder: Folder` 추가. 호출부에서 `LinkView`의 `folder` 변수 전달.
- **렌더 조건 (기존 `childFolders.isEmpty` 조건을 대체)**:
  - `state is! LinkListLoadedState` → `SizedBox.shrink`
  - `currentFolder.isClassified == false` (미분류) → `SizedBox.shrink` (섹션 전체 숨김)
  - 그 외 → 헤더 + (자식 있으면 목록, 없으면 "하위 폴더 없음" 문구) 항상 렌더
- 헤더에 우측 `Align`으로 "+" 아이콘 버튼(`Icons.create_new_folder_outlined`, 18.sp, `primary600`, InkWell 8.w 패딩).
- 자식 0개일 때 헤더 아래 `"하위 폴더 없음"` (13.sp `grey400`) 문구 렌더.

`_onAddChildFolder(context, parent)` 헬퍼 추가:
- `showCreateFolderSheet(context, initialParentId: parent.id, allowParentPick: true)`
- 성공 시 `showBottomToast("'${parent.name}' 아래에 폴더가 생성되었어요!")`
- `LocalLinksFromFolderCubit.refresh()` + `LocalFoldersCubit.getFolders()` 호출
- **부모에 머무름** (네비게이션 안 함)

### 수정: `lib/ui/widget/dialog/bottom_dialog.dart` — `showFolderOptionsDialog`

기존 3개 `BottomListItem` 위에 "하위 폴더 추가" 항목 추가:

```dart
BottomListItem(
  '하위 폴더 추가',
  callback: () async {
    Navigator.pop(context);
    final newId = await showCreateFolderSheet(
      parentContext,
      initialParentId: currFolder.id,
    );
    if (newId != null && parentContext.mounted) {
      showBottomToast(
        context: parentContext,
        "'${currFolder.name}' 아래에 폴더가 생성되었어요!",
      );
      parentContext.read<LocalFoldersCubit>().getFolders();
      if (fromLinkView) {
        parentContext.read<LocalLinksFromFolderCubit>().refresh();
      }
    }
  },
),
```

옵션 시트는 분류된 폴더에서만 띄우므로 미분류 가드 추가 불필요. `saveEmptyFolder`/`runCallback` 삭제.

### 폐기

- `lib/ui/widget/add_folder/show_add_folder_dialog.dart` — 이번 스펙에서 삭제
- `lib/ui/widget/dialog/bottom_dialog.dart`의 `saveEmptyFolder`, `runCallback` — 이번 스펙에서 삭제
- `lib/cubits/folders/folder_name_cubit.dart` — **rename 다이얼로그가 아직 사용 중이라 이번 스펙에서는 유지**. rename 경로까지 정리되면 폐기 가능. 후속 리팩터링 스펙으로 이관.

### 호출부 전환

- `lib/ui/page/my_folder/my_folder_page.dart:179`:
  ```dart
  final newId = await showCreateFolderSheet(context);
  if (newId == null || !context.mounted) return;
  await context.read<LocalFoldersCubit>().getFolders();
  final folders = context.read<LocalFoldersCubit>().folders;
  moveToMyLinksView(context, folders, folders.length - 1); // 신규 폴더로 이동 유지
  showBottomToast(context: context, '새로운 폴더가 생성되었어요!');
  ```
- `lib/ui/widget/add_folder/folder_add_title.dart:26`:
  ```dart
  final newId = await showCreateFolderSheet(
    context,
    allowParentPick: false, // 공유/업로드 플로우는 루트 고정
  );
  if (newId == null || !context.mounted) return;
  await context.read<LocalFoldersCubit>().getFoldersWithoutUnclassified();
  final folders = context.read<LocalFoldersCubit>().folders;
  moveToMyLinksView?.call(context, folders, folders.length - 1);
  callback?.call();
  showBottomToast(context: context, '새로운 폴더가 생성되었어요!');
  ```

## 데이터 흐름 시나리오

### A. 무료 사용자, 루트 생성
`showCreateFolderSheet` → `LocalFoldersCubit.createFolder("신규", parentId: null)` → `isSiblingNameTaken(null, …)` → DB INSERT → `ProRemoteHooks.onFolderUpserted` no-op (비-Pro) → `getFolders()` → 시트 pop → 토스트 + 그리드 갱신.

### B. 무료 사용자, 중첩 생성 (MyLinkView)
`_onAddChildFolder(parent)` → `showCreateFolderSheet(initialParentId: parent.id, allowParentPick: true)` → 사용자 parentId 유지 → Cubit이 `Created(id)` 반환 → 시트가 `Navigator.pop(context, id)` → 호출부가 `id != null` 확인 후 토스트 + **부모에 머무름**, `LocalLinksFromFolderCubit.refresh()` 로 자식 리스트 갱신.

### C. Pro 사용자, 정상 경로
`createFolder` → DB INSERT → `ProRemoteHooks.onFolderUpserted(folder with parentId)` → `SyncRepository.upsertFolderRemote`:
1. `_resolveRemoteFolderId(userId, parentId)` → `'aaa-uuid'`
2. `remoteWrite(upsert(parent_id: 'aaa-uuid', ...))`
3. `dirty=false`

### D. Pro 사용자, 부모 원격 미해결
`_resolveRemoteFolderId` → `null` → `_setDirty(true)` + 조기 반환. 로컬 DB는 정상, 원격만 뒤처짐. 다음 `mergeWithRemote` 또는 `backupToRemote`가 `merge_compute.dart`의 path_key 로직으로 복원.

### E. 이름 중복 (형제 범위)
`createFolder` → `isSiblingNameTaken` true → Cubit `DuplicateSibling` 반환 → 시트 `_errorText` 주입 + 시트 유지. 사용자 이름 수정 시 `_errorText=null`. 부모 변경 시도 `_errorText=null` 초기화.

### F. 20자 초과
TextField validator 단계에서 처리, Cubit 호출 안 감.

### G. 공유/업로드 플로우
`showCreateFolderSheet(allowParentPick: false)` → 시트에 ParentRow 미렌더 → 루트 고정 생성 → `getFoldersWithoutUnclassified()` 갱신 → 신규 폴더 기본 선택.

### H. 미분류 폴더에서 하위 추가?
`MyLinkView`의 "하위 폴더 (N)" 섹션이 `isClassified == false`일 때 전체 숨김 + `showFolderOptionsDialog` 자체가 미분류에서는 띄워지지 않음 → UI 경로 전부 봉쇄. Repository의 `_assertNotUnclassified`는 이중 안전망.

## 에러 처리 & 엣지 케이스

| ID | 상황 | 처리 |
|---|---|---|
| E1 | 더블 탭 submit | `_submitting` 플래그로 UI 차단 + Repository 레벨 `isSiblingNameTaken` 재검사 |
| E2 | 부모 폴더 삭제 후 생성 | `createFolder`에 `getFolderById(parentId)` 가드 추가 → `StateError` → Cubit null → 시트 `_errorText = "상위 폴더를 찾을 수 없어요. 다시 선택해주세요."` |
| E3 | 피커 열린 사이 구조 변경 | 저장 시점 E2 가드가 자동 커버. 피커 자체 실시간 반영은 범위 밖 |
| E4 | 순환 참조 | 생성 시 새 id 발급 → 불가. `moveFolder` 가드 유지 |
| E5 | 공백 이름 | Cubit 호출 전 `name.trim()`. 빈 결과 거부 |
| E6 | 대소문자/유니코드 정규화 | **하지 않음** (바이트-equal) |
| E7 | 배경 탭/뒤로가기 | `showModalBottomSheet` 기본 dismiss, `null` 반환, 호출부 no-op |
| E8 | 공유 플로우 + 신규 사용자 | `getFoldersWithoutUnclassified` 후 `moveToMyLinksView`를 호출부에서 인라인 처리 |
| E9 | `_resolveRemoteFolderId` 예외 | try/catch 후 `dirty=true` + 조기 반환. 링크 경로도 동일 (1단계 승격) |
| E10 | 무료→Pro 전환 직전 깊은 중첩 | `backupToRemote`의 parent 2-pass 루프 기존 유지, 최적화 범위 밖 |
| E11 | 고아 부모(다른 디바이스에서 삭제됨) | E2와 동일 경로 |
| E12 | `allowParentPick: false` 플로우에서 `ParentMissing` 발생? | 공유/업로드는 항상 `parentId=null` 고정이므로 경로상 발생 불가. UI에 재선택 수단이 없어도 문제없음 |

### 에러 메시지 카피

| 상황 | 메시지 | 표시 경로 |
|---|---|---|
| 공백/빈 이름 | `폴더 이름을 입력해주세요.` | submit 시 `_errorText` 주입 |
| 20자 초과 | `20자 이하로 입력해주세요.` | TextFormField validator (onChange) |
| 형제 중복 | `같은 위치에 이미 같은 이름의 폴더가 있어요. 다른 이름을 입력해주세요.` | submit 시 `_errorText` 주입 |
| 상위 사라짐 | `상위 폴더를 찾을 수 없어요. 다시 선택해주세요.` | submit 시 `_errorText` 주입 |
| 알 수 없는 실패 | `폴더를 만들지 못했어요. 잠시 후 다시 시도해주세요.` | submit 시 `_errorText` 주입 |
| 성공 루트 | `새로운 폴더가 생성되었어요!` | 하단 토스트 (호출부) |
| 성공 중첩 | `'부모명' 아래에 폴더가 생성되었어요!` | 하단 토스트 (호출부) |

`_errorText`는 TextFormField의 `decoration.errorText`로 전달되어 같은 위치(입력 필드 아래)에 빨간색으로 렌더된다.

## 테스트 전략

전체 커버리지 80%+ 유지 (CLAUDE.md 규칙).

### T1. Repository 테스트 (`test/provider/local/local_folder_repository_test.dart` 확장)

- `isSiblingNameTaken` — 루트 범위, 자식 범위, 다른 부모 아래 동명 허용, 루트 이름과 중첩 이름 독립, **공백 포함 이름은 trim되지 않고 그대로 비교됨**을 검증 (trim은 Cubit/시트 책임)
- `createFolder` 중첩 — 성공, 미분류 부모 거부, 존재하지 않는 부모 거부, 훅 파라미터에 parentId 포함

### T2. Cubit 테스트 (`test/cubits/folders/local_folders_cubit_test.dart`)

- `createFolder(parentId: 42)` 성공 → `Created(id)` 반환 + `FolderLoadingState` → `FolderLoadedState` emit
- 형제 중복 → `DuplicateSibling` 반환, emit 없음
- Repository `StateError('부모 폴더가 존재하지 않습니다.')` → `ParentMissing` 반환
- Repository 그 외 예외 → `Failed(e)` 반환

### T3. Sync 테스트 (`test/provider/sync/sync_repository_upsert_test.dart`, 신규)

- `parentId=null` → `parent_id=null` 업서트
- `parentId` 있고 원격 부모 존재 → 해결된 uuid로 업서트
- 부모 미해결 → 업서트 0회 + dirty 세팅
- `_resolveRemoteFolderId` 예외 → 삼키고 dirty 세팅 (E9)

### T4. Widget — `showCreateFolderSheet`

- autofocus + 초기 disabled
- 이름 입력 → 활성화
- 20자 초과 inline 에러 + disable
- `allowParentPick=false` → ParentRow 미렌더
- `initialParentId` 주어지면 ParentRow에 브레드크럼 경로
- ParentRow 탭 → `showPickFolderSheet` 호출 + 반영
- 중복 submit → `_errorText` 주입 + 시트 유지
- 더블 탭 → `_submitting` disable

### T5. Widget — `MyLinkView` 중첩

- 분류된 폴더 → "+" 버튼 + 0개일 때 "하위 폴더 없음" 표시
- 미분류 폴더 → 섹션 전체 숨김
- "+" 탭 → `showCreateFolderSheet(initialParentId: currentFolder.id)`
- 생성 완료 → 토스트 + childFolders 갱신

### T6. Widget — `showFolderOptionsDialog`

- "하위 폴더 추가" 항목이 맨 위에 있음
- 탭 → 옵션 시트 닫힘 + `showCreateFolderSheet` 열림

### T7. E2E (`integration_test/nested_folder_create_test.dart`, 신규)

골든 플로우 1개: 루트 `개발` 생성 → `개발` 진입 → "+ 하위 폴더" → `React` 입력 → 생성 → `하위 폴더 (1) > React` 노출 → `React` 진입 → 브레드크럼 `루트 > 개발 > React` 확인.

### T8. Pro 동기화 수동 체크리스트

- [ ] Pro 로그인 → 루트 A 생성 → Supabase folders에 `client_id=A.id, parent_id=null`
- [ ] A 진입 → "+ 하위 폴더" → B 생성 → `parent_id='A의 uuid'`
- [ ] 오프라인 → B 아래 C 생성 → 온라인 복귀 → dirty 보정 후 C 업서트 (`parent_id=B의 uuid`)
- [ ] 원격 A 강제 삭제 후 A 아래 D 생성 → 로컬 존재, 원격 없음, dirty=true → 수동 백업/머지로 복원

## 구현 순서 (Phase 1)

| 단계 | 내용 | 단독 머지 가능 |
|---|---|---|
| 1 | `upsertFolderRemote` 2-pass + `upsertLinkRemote` 예외 try/catch + 테스트(T3) | ✅ |
| 2 | `isSiblingNameTaken` 추가, `createFolder`에 부모 존재 가드 + 테스트(T1) | ✅ |
| 3 | `LocalFoldersCubit.createFolder`에 `parentId` 추가 + 테스트(T2) | ✅ (하위 호환) |
| 4 | `showCreateFolderSheet` 신규 + 테스트(T4) | ✅ (죽은 코드 상태) |
| 5 | 호출부 전환 (`my_folder_page`, `folder_add_title`) + 구 다이얼로그/Cubit 삭제 | ✅ |
| 6 | `MyLinkView` 중첩 진입점 + 테스트(T5) | ✅ |
| 7 | `showFolderOptionsDialog`에 "하위 폴더 추가" + 테스트(T6) | ✅ |
| 8 | E2E 골든 플로우 (T7) | ✅ |
| 9 | T8 수동 체크리스트 완주 | — |

### Phase 1 종료 기준

- 1~8단계 전부 완료
- `fvm flutter analyze` 깨끗
- `fvm flutter test` 전부 green
- T8 체크리스트 완주 (Pro 실기기 1회)
- 3개 진입점(루트 "+", MyLinkView "+", 옵션 "하위 폴더 추가")에서 생성 성공 수기 확인
- 공유/업로드 플로우 루트 생성 회귀 없음 수기 확인

## Phase 2 — 확장 초안

트리거 위치 후보:
- `FolderTree` 상단 툴바에 루트 "+ 새 폴더"
- 각 `FolderTreeItem` 호버 시 우측 "+" (그 폴더를 parentId로)

공유 팔레트: 확장은 이미 `fill="#741FFF"`(primary700)를 폴더 아이콘에 사용 중이라 앱과 동일 디자인 언어 위에 있음. 아이콘은 outlined folder + "+" 패턴.

Phase 2 시작 시 결정해야 할 것들:
- 모달 다이얼로그 vs 인라인 input (Notion 스타일)
- 형제 중복 검사를 `storage` vs `useFolderTree` 어디에 둘지
- 수동 생성 폴더(`bookmark_id=null`)와 북마크 동기화의 상호작용
- 루트 "+" 와 행 호버 "+" 중 primary 포지션

Phase 2 스펙은 Phase 1 종료 후 별도 업데이트로 확정.

## Out of scope

1. 중첩 `moveFolder` UX 개선(DnD, 일괄 이동, 복사)
2. 깊이 제한
3. `backupToRemote` 대규모 폴더 최적화 (E10)
4. 경로 기반 검색/입력 폼
5. 본 스펙이 건드리는 파일 외의 리팩터링(`showFolderOptionsDialog` 복잡도 등)
6. 원격 스키마 변경(parent_id uuid 컬럼 이미 존재)
7. 대소문자/유니코드 정규화 (E6)
8. 부모 썸네일/아이콘 계승

## Verification 체크리스트

- [ ] `upsertFolderRemote`가 `parentId != null`이면 `_resolveRemoteFolderId`로 uuid 해결 후 `parent_id` 포함 업서트
- [ ] 부모 미해결 시 `_setDirty(true)` + 조기 반환
- [ ] 부모 미해결 → 머지/백업 경로에서 치유 (`merge_compute.dart`/`backupToRemote` 기존 동작 유지)
- [ ] `onFolderDeleted` 경로는 `match: {user_id, client_id}`로 원격 제거 (CASCADE로 자손 정리)
- [ ] `moveFolder` 후 `upsertFolderRemote`가 새 parent 반영된 `LocalFolder`로 재호출됨
- [ ] 모든 이름 중복 검사가 **형제 범위**에서 이뤄짐 (전역 X)
- [ ] 미분류 폴더 아래 생성 경로 전부 봉쇄 (UI + Repository 이중)
