# 오프라인 모드 마이그레이션 문서

## 개요

LinkPool 앱을 서버 API 의존에서 로컬 SQLite 데이터베이스 기반의 오프라인 모드로 마이그레이션한 작업을 정리한 문서입니다.

### 마이그레이션 목표

1. 모든 폴더/링크 데이터를 로컬 SQLite에 저장
2. 서버 API 호출을 최소화 (로그인, 마이그레이션용만 유지)
3. 소셜 기능 제거 (공유 폴더, 피드, 신고 등)
4. 기존 사용자 데이터를 서버에서 로컬로 마이그레이션

### 유지된 서버 API

| API | 용도 |
|-----|------|
| UserApi | 로그인, 회원가입, 프로필 관리 |
| ProfileApi | 프로필 정보 조회/수정 |
| SaveOfflineApi | 마이그레이션 상태 확인 및 완료 표시 |
| FolderApi | 마이그레이션 시 서버 폴더 조회 |
| LinkApi | 마이그레이션 시 서버 링크 조회 |

---

## Phase 1: 로컬 데이터베이스 인프라 구축

### 생성된 파일

| 파일 | 설명 |
|------|------|
| `lib/provider/local/database_helper.dart` | SQLite 데이터베이스 헬퍼 (싱글톤) |
| `lib/provider/local/local_folder_repository.dart` | 로컬 폴더 CRUD 저장소 |
| `lib/provider/local/local_link_repository.dart` | 로컬 링크 CRUD 저장소 |
| `lib/provider/local/local_bulk_repository.dart` | 대량 데이터 처리 저장소 |
| `lib/models/local/local_folder.dart` | 로컬 폴더 모델 |
| `lib/models/local/local_link.dart` | 로컬 링크 모델 |

### 데이터베이스 스키마

```sql
-- folders 테이블
CREATE TABLE folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id INTEGER,
  name TEXT NOT NULL,
  visible INTEGER DEFAULT 1,
  seq INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);

-- links 테이블
CREATE TABLE links (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id INTEGER,
  folder_id INTEGER NOT NULL,
  url TEXT NOT NULL,
  title TEXT,
  describe TEXT,
  image TEXT,
  time TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
);
```

---

## Phase 2: 로컬 Cubit 생성

### 생성된 Cubit 파일

| 파일 | 대체 대상 | 설명 |
|------|-----------|------|
| `lib/cubits/folders/local_folders_cubit.dart` | GetMyFoldersCubit | 로컬 폴더 목록 관리 |
| `lib/cubits/links/local_links_cubit.dart` | GetLinksCubit | 전체 링크 목록 (페이지네이션) |
| `lib/cubits/links/local_links_from_folder_cubit.dart` | LinksFromSelectedFolderCubit | 폴더별 링크 목록 |
| `lib/cubits/links/local_upload_link_cubit.dart` | UploadLinkCubit | 링크 업로드/수정 |
| `lib/cubits/links/local_detail_edit_cubit.dart` | DetailEditCubit | 링크 상세 편집 |
| `lib/cubits/home/local_search_links_cubit.dart` | SearchLinksCubit | 링크 검색 |

### Cubit 패턴

```dart
class LocalFoldersCubit extends Cubit<FoldersState> {
  LocalFoldersCubit() : super(const FoldersLoadingState()) {
    getFolders();
  }

  final LocalFolderRepository _repository = getIt();

  Future<void> getFolders() async {
    emit(const FoldersLoadingState());
    final folders = await _repository.getAllFolders();
    emit(FoldersLoadedState(folders));
  }
}
```

---

## Phase 3: UI 통합

### 수정된 View 파일

| 파일 | 변경 내용 |
|------|-----------|
| `lib/ui/view/home_view.dart` | HomePage → LocalExplorePage, LocalFoldersCubit 사용 |
| `lib/ui/page/my_folder/my_folder_page.dart` | GetFoldersCubit → LocalFoldersCubit |
| `lib/ui/view/upload_view.dart` | LocalFoldersCubit, LocalUploadLinkCubit 사용 |
| `lib/ui/view/links/my_link_view.dart` | LocalFoldersCubit, LocalLinksFromFolderCubit, LocalLinkRepository |
| `lib/ui/view/links/link_detail_view.dart` | LocalDetailEditCubit, LocalUploadLinkCubit |
| `lib/ui/view/links/search_view.dart` | LocalSearchLinksCubit, LocalUploadLinkCubit |
| `lib/ui/widget/dialog/bottom_dialog.dart` | LocalFoldersCubit, LocalLinkRepository |
| `lib/ui/widget/move_to_my_folder_dialog.dart` | LocalFoldersCubit, LocalUploadLinkCubit |
| `lib/ui/widget/dialog/center_dialog.dart` | LocalFoldersCubit |
| `lib/ui/widget/rename_folder/show_rename_folder_dialog.dart` | LocalFoldersCubit |
| `lib/ui/view/links/shared_link_setting_view.dart` | LocalFoldersCubit |

### 생성된 View 파일

| 파일 | 설명 |
|------|------|
| `lib/ui/page/home/local_explore_page.dart` | 로컬 전체 링크 탐색 페이지 (HomePage 대체) |

---

## Phase 4: 코드 청소 및 소셜 기능 제거

### 삭제된 Cubit 파일 (13개)

```
lib/cubits/feed/feed_view_cubit.dart
lib/cubits/folders/delegate_admin_cubit.dart
lib/cubits/folders/folder_users_state.dart
lib/cubits/folders/get_my_folders_cubit.dart
lib/cubits/folders/get_user_folders_cubit.dart
lib/cubits/home/search_links_cubit.dart
lib/cubits/linkpool_pick/linkpool_pick_cubit.dart
lib/cubits/linkpool_pick/linkpool_pick_result_state.dart
lib/cubits/links/detail_edit_cubit.dart
lib/cubits/links/get_links_cubit.dart
lib/cubits/links/links_from_selected_folder_cubit.dart
lib/cubits/links/upload_link_cubit.dart
lib/cubits/report/report_cubit.dart
```

### 삭제된 API 파일 (3개)

```
lib/provider/api/folders/share_folder_api.dart
lib/provider/api/linkpool_pick/linkpool_pick_api.dart
lib/provider/api/report/report_api.dart
```

### 삭제된 View 파일 (6개)

```
lib/ui/page/home/home_page.dart          # 소셜 피드 페이지
lib/ui/view/delegate_admin_view.dart     # 공유 폴더 관리자 위임
lib/ui/view/links/share_invite_dialog.dart  # 공유 폴더 초대
lib/ui/view/links/user_feed_view.dart    # 다른 사용자 피드
lib/ui/view/report_view.dart             # 신고 페이지
lib/ui/widget/user/user_info.dart        # 사용자 프로필 위젯 (오프라인 모드에서 불필요)
```

### 삭제된 테스트 파일

```
test/provider/api/report/report_api_test.dart
```

### 비활성화/제거된 기능

| 기능 | 파일 | 변경 내용 |
|------|------|-----------|
| 신고하기 | `bottom_dialog.dart` | 신고 메뉴 항목 제거 |
| 공유 초대 | `bottom_dialog.dart`, `my_link_view.dart` | showInviteDialog 호출 제거 |
| 사용자 프로필 표시 | `user_info.dart` | 파일 삭제 (오프라인 모드에서 불필요) |
| 방장 권한 위임 | `delete_share_folder_dialog.dart` | 위임 버튼 제거 |
| 카카오 공유 폴더 | `kakao.dart` | folderId/userId 관련 코드 제거 |
| 로그아웃/회원탈퇴 | `my_page.dart` | 오프라인 모드 완료 시 메뉴 숨김 |

---

## Phase 5: 마이그레이션 서비스

### 생성된 파일

| 파일 | 설명 |
|------|------|
| `lib/provider/api/save_offline/save_offline_api.dart` | 마이그레이션 상태 API |
| `lib/provider/local/offline_migration_service.dart` | 서버→로컬 마이그레이션 서비스 |
| `lib/provider/offline_mode_provider.dart` | 오프라인 모드 완료 상태 로컬 저장 |
| `lib/util/migration_logger.dart` | 마이그레이션 로그 파일 생성 |

### 마이그레이션 플로우

```
1. 사용자 로그인
   ↓
2. 마이그레이션 완료 여부 확인 (SaveOfflineApi.getSaveOfflineHistory)
   ↓
3. 미완료 시 마이그레이션 실행:
   a. 서버에서 모든 폴더 조회 (FolderApi.getMyFolders)
   b. 각 폴더별 링크 조회 (LinkApi.getLinksFromSelectedFolder, 페이지네이션)
   c. 미분류 링크 조회 (LinkApi.getUnClassifiedLinks, 페이지네이션)
   d. 로컬 DB에 저장 (LocalBulkRepository.migrateFromServer)
   e. 마이그레이션 완료 표시 (SaveOfflineApi.completeSaveOffline)
   ↓
4. 이후 모든 데이터는 로컬 DB 사용
```

> **Note**: 기존에 `LinkApi.getLinks()` (job-groups API)를 사용했으나, 이 API는 소셜 피드용이므로
> 폴더별 링크 순회 방식으로 변경됨.

---

## DI 설정 변경

### `lib/di/set_up_get_it.dart`

```dart
void locator() {
  final httpClient = CustomClient();
  final databaseHelper = DatabaseHelper.instance;

  getIt
    ..registerLazySingleton(() => httpClient)

    // APIs (로그인, 마이그레이션, 프로필용)
    ..registerLazySingleton(() => UserApi(httpClient))
    ..registerLazySingleton(() => ProfileApi(httpClient))
    ..registerLazySingleton(() => SaveOfflineApi(httpClient))

    // Local Repositories (오프라인 모드 핵심)
    ..registerLazySingleton(() => databaseHelper)
    ..registerLazySingleton(() => LocalFolderRepository(databaseHelper: databaseHelper))
    ..registerLazySingleton(() => LocalLinkRepository(databaseHelper: databaseHelper))
    ..registerLazySingleton(() => LocalBulkRepository(databaseHelper: databaseHelper))

    // Services
    ..registerLazySingleton(OfflineMigrationService.new)

    // Cubits
    ..registerLazySingleton(GetProfileInfoCubit.new)
    ..registerLazySingleton(AutoLoginCubit.new)
    ..registerLazySingleton(AppPauseManager.new);
}
```

---

## Routes 변경

### 삭제된 라우트

```dart
// 삭제됨
static const userFeed = '/userFeed';
static const delegateAdmin = '/delegateAdmin';
static const report = '/report';
```

### 유지된 라우트

```dart
// links
static const home = '/home';
static const linkDetail = '/linkDetail';
static const myLinks = '/myLinks';
static const search = '/search';
static const sharedLinkSetting = '/sharedLinkSetting';

// user
static const profile = '/profile';
static const emailLogin = '/emailLogin';
static const login = '/login';
static const signUpNickname = '/signUpNickname';

// etc
static const splash = '/splash';
static const terms = '/terms';
static const myPage = '/myPage';
static const upload = '/upload';
static const tutorial = '/tutorial';
static const ossLicenses = '/ossLicenses';
```

---

## 테스트 결과

- 전체 테스트: **92개 통과**
- 삭제된 테스트: 1개 (report_api_test.dart)
- 커버리지 테스트 파일 업데이트 완료

---

## 커밋 히스토리

| 커밋 | 내용 |
|------|------|
| Phase 1 | 로컬 데이터베이스 인프라 구축 |
| Phase 2 | 로컬 Cubit 생성 |
| Phase 3 | UI 통합 및 LocalExplorePage 생성 |
| Phase 4 | DI 설정 정리, 사용하지 않는 의존성 제거 |
| Phase 5 | 소셜 기능 및 사용하지 않는 API/Cubit 제거 |

---

## 통계

| 항목 | 수치 |
|------|------|
| 생성된 파일 | ~16개 |
| 수정된 파일 | ~25개 |
| 삭제된 파일 | ~23개 |
| 삭제된 코드 | ~3,200줄 |
| 추가된 코드 | ~2,100줄 |

---

## 주의사항

1. **마이그레이션 API 유지**: FolderApi와 LinkApi는 마이그레이션 서비스에서 사용하므로 파일은 유지됨
2. **공유 폴더 UI 잔존**: SharedLinkSettingView는 일반 폴더 설정에도 사용되어 유지됨
3. **카카오 링크 공유**: 로컬 링크 조회로 변경됨, 공유 폴더 관련 기능은 비활성화됨

---

## 향후 작업 (선택사항)

1. [x] ~~마이그레이션 실행 UI 추가 (스플래시 또는 로그인 후)~~ - 자동 로그인/수동 로그인 시 마이그레이션 실행
2. [ ] 로컬 데이터 백업/복원 기능
3. [ ] 오프라인 상태 감지 및 UI 표시
4. [x] ~~남아있는 공유 폴더 관련 코드 완전 제거~~ - 프로필 UI 제거 완료

---

## 수정 이력

### 2026-02-06: 마이그레이션 링크 수집 방식 변경

**문제점**:
- 기존 `LinkApi.getLinks()` API (`/job-groups/0/links`)는 소셜 피드용 API로, 사용자의 개인 링크를 가져오는 용도가 아니었음
- 마이그레이션 시 일부 링크가 누락될 수 있는 위험이 있었음

**변경 내용**:
- `LinkApi.getLinks()` → 폴더별 순회 방식으로 변경
- 각 폴더의 링크: `LinkApi.getLinksFromSelectedFolder(folder, page)`
- 미분류 링크: `LinkApi.getUnClassifiedLinks(page)`

**수정된 파일**:
- `lib/provider/local/offline_migration_service.dart`

---

### 2026-02-06: 오프라인 모드 완료 상태 로컬 저장

**문제점**:
- 마이그레이션 완료 후에도 매번 서버에 완료 여부를 확인해야 했음
- 서버 API 의존성이 불필요하게 남아있었음

**변경 내용**:
- `OfflineModeProvider` 생성: SharedPreferences에 오프라인 모드 완료 상태 저장
- 마이그레이션 성공 시 로컬에 완료 상태 저장
- 앱 시작 시 로컬 완료 상태 확인 → 완료 시 로그인 과정 스킵
- 로그아웃 시 오프라인 모드 상태 초기화 (다른 계정 로그인 대비)

**수정/생성된 파일**:
- `lib/provider/offline_mode_provider.dart` (신규)
- `lib/provider/local/offline_migration_service.dart` - 완료 시 `OfflineModeProvider.setOfflineModeCompleted()` 호출
- `lib/ui/view/splash_view.dart` - 오프라인 완료 시 로그인 스킵
- `lib/provider/logout.dart` - 로그아웃 시 `OfflineModeProvider.clearOfflineMode()` 호출

---

### 2026-02-06: 설정 페이지 UI 변경

**변경 내용**:
- 프로필 기반 UI 제거, 단순 "설정" 헤더로 변경
- 오프라인 모드 완료 시 `로그아웃`, `회원탈퇴` 메뉴 숨김

**수정된 파일**:
- `lib/ui/page/my_page/my_page.dart`

---

### 2026-02-06: 링크 상세/검색 화면 프로필 UI 제거

**문제점**:
- 오프라인 모드에서 다른 사용자 개념이 없으므로 프로필 이미지/닉네임 표시가 불필요

**변경 내용**:
- `UserInfoWidget` (프로필 이미지 + 닉네임) 제거
- `GetProfileInfoCubit` 의존성 제거
- 모든 링크를 내 링크로 처리하도록 단순화

**수정/삭제된 파일**:
- `lib/ui/view/links/link_detail_view.dart` - UserInfoWidget 제거, 프로필 비교 로직 제거
- `lib/ui/view/links/search_view.dart` - UserInfoWidget 제거, 항상 `showMyLinkOptionsDialog` 사용
- `lib/ui/widget/user/user_info.dart` (삭제) - 더 이상 사용되지 않음
