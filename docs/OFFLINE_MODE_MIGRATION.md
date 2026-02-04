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

### 삭제된 View 파일 (5개)

```
lib/ui/page/home/home_page.dart          # 소셜 피드 페이지
lib/ui/view/delegate_admin_view.dart     # 공유 폴더 관리자 위임
lib/ui/view/links/share_invite_dialog.dart  # 공유 폴더 초대
lib/ui/view/links/user_feed_view.dart    # 다른 사용자 피드
lib/ui/view/report_view.dart             # 신고 페이지
```

### 삭제된 테스트 파일

```
test/provider/api/report/report_api_test.dart
```

### 비활성화된 기능

| 기능 | 파일 | 변경 내용 |
|------|------|-----------|
| 신고하기 | `bottom_dialog.dart` | 신고 메뉴 항목 제거 |
| 공유 초대 | `bottom_dialog.dart`, `my_link_view.dart` | showInviteDialog 호출 제거 |
| 사용자 피드 이동 | `user_info.dart` | 탭 동작 비활성화 |
| 방장 권한 위임 | `delete_share_folder_dialog.dart` | 위임 버튼 제거 |
| 카카오 공유 폴더 | `kakao.dart` | folderId/userId 관련 코드 제거 |

---

## Phase 5: 마이그레이션 서비스

### 생성된 파일

| 파일 | 설명 |
|------|------|
| `lib/provider/api/save_offline/save_offline_api.dart` | 마이그레이션 상태 API |
| `lib/provider/local/offline_migration_service.dart` | 서버→로컬 마이그레이션 서비스 |

### 마이그레이션 플로우

```
1. 사용자 로그인
   ↓
2. 마이그레이션 완료 여부 확인 (SaveOfflineApi.getSaveOfflineHistory)
   ↓
3. 미완료 시 마이그레이션 실행:
   a. 서버에서 모든 폴더 조회 (FolderApi.getMyFolders)
   b. 서버에서 모든 링크 조회 (LinkApi.getLinks, 페이지네이션)
   c. 로컬 DB에 저장 (LocalBulkRepository.migrateFromServer)
   d. 마이그레이션 완료 표시 (SaveOfflineApi.completeSaveOffline)
   ↓
4. 이후 모든 데이터는 로컬 DB 사용
```

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
| 생성된 파일 | ~15개 |
| 수정된 파일 | ~20개 |
| 삭제된 파일 | ~22개 |
| 삭제된 코드 | ~3,000줄 |
| 추가된 코드 | ~2,000줄 |

---

## 주의사항

1. **마이그레이션 API 유지**: FolderApi와 LinkApi는 마이그레이션 서비스에서 사용하므로 파일은 유지됨
2. **공유 폴더 UI 잔존**: SharedLinkSettingView는 일반 폴더 설정에도 사용되어 유지됨
3. **카카오 링크 공유**: 로컬 링크 조회로 변경됨, 공유 폴더 관련 기능은 비활성화됨

---

## 향후 작업 (선택사항)

1. [ ] 마이그레이션 실행 UI 추가 (스플래시 또는 로그인 후)
2. [ ] 로컬 데이터 백업/복원 기능
3. [ ] 오프라인 상태 감지 및 UI 표시
4. [ ] 남아있는 공유 폴더 관련 코드 완전 제거
