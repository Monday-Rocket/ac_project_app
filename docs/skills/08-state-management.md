---
name: app-state-management
description: Flutter 앱 BLoC/Cubit 패턴 — 22개 Cubit, DI(GetIt), 상태 흐름
type: feature
project: ac_project_app
tier: core
---

# 상태 관리 (State Management)

## 개요
flutter_bloc의 Cubit 패턴으로 상태 관리. GetIt으로 DI. 22개 Cubit이 각 기능 담당.

## DI 설정 (`lib/di/set_up_get_it.dart`)
```dart
// Singleton 등록
GetIt.instance
  ..registerSingleton<DatabaseHelper>(DatabaseHelper())
  ..registerSingleton<LocalFolderRepository>(...)
  ..registerSingleton<LocalLinkRepository>(...)
  ..registerSingleton<LocalBulkRepository>(...)
  ..registerSingleton<AuthRepository>(...)
  ..registerSingleton<SyncRepository>(...)
```

## Cubit 목록

### 폴더 관련
| Cubit | 파일 | 역할 |
|-------|------|------|
| LocalFoldersCubit | `cubits/folders/local_folders_cubit.dart` | 폴더 CRUD |
| GetSelectedFolderCubit | `cubits/folders/get_selected_folder_cubit.dart` | 선택된 폴더 |
| FolderNameCubit | `cubits/folders/folder_name_cubit.dart` | 폴더 이름 입력 |
| FolderVisibleCubit | `cubits/folders/folder_visible_cubit.dart` | 표시/숨김 |

### 링크 관련
| Cubit | 파일 | 역할 |
|-------|------|------|
| LocalLinksCubit | `cubits/links/local_links_cubit.dart` | 전체 링크 + 페이지네이션 |
| LocalLinksFromFolderCubit | `cubits/links/local_links_from_folder_cubit.dart` | 폴더별 링크 |
| LocalSearchLinksCubit | `cubits/home/local_search_links_cubit.dart` | 검색 |
| LocalUploadLinkCubit | `cubits/links/local_upload_link_cubit.dart` | 링크 생성 |
| LocalDetailEditCubit | `cubits/links/local_detail_edit_cubit.dart` | 편집/삭제/이동 |
| HasMoreCubit | `cubits/links/has_more_cubit.dart` | 페이지네이션 상태 |

### 인증
| Cubit | 파일 | 역할 |
|-------|------|------|
| AuthCubit | `cubits/auth/auth_cubit.dart` | 로그인/로그아웃 |

### UI 상태
| Cubit | 파일 | 역할 |
|-------|------|------|
| HomeViewCubit | `cubits/home_view_cubit.dart` | 홈 탭 인덱스 |
| HomeSecondViewCubit | `cubits/home_second_view_cubit.dart` | 보조 네비게이션 |
| ScrollCubit | `cubits/scroll_cubit.dart` | 스크롤 위치 |
| ButtonStateCubit | `cubits/button_state_cubit.dart` | 버튼 활성화 |

## 의존성
- `flutter_bloc: ^9.1.1`
- `get_it: ^9.2.0`
- `equatable: ^2.0.5`

## 수정 시 주의사항
- Cubit 추가 시 `set_up_get_it.dart`에 Repository 등록 확인
- BlocProvider는 화면 레벨에서 제공 (routes.dart 또는 해당 page)
- 테스트: `bloc_test: ^10.0.0` + `mockito: ^5.4.4` 사용
