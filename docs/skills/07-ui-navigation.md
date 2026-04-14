---
name: app-ui-navigation
description: Flutter 앱 화면 구조 — 라우팅, 탭 네비게이션, 위젯 라이브러리, 테마
type: feature
project: ac_project_app
tier: core
---

# UI 및 네비게이션 (UI & Navigation)

## 개요
Bottom Navigation 3탭 구조 + 모달 라우트. Cubit 기반 상태 관리, 반응형 UI.

## 라우팅 (`lib/routes.dart`)

| 경로 | 화면 | 설명 |
|------|------|------|
| `/splash` | SplashView | 애니메이션 인트로 (1.5초) |
| `/home` | HomeView | 메인 (3탭 Bottom Nav) |
| `/upload` | UploadView | 링크 업로드 |
| `/myLinks` | MyLinkView | 폴더 내 링크 목록 |
| `/search` | SearchView | 글로벌 검색 |
| `/linkDetail` | LinkDetailView | 링크 상세/편집 |
| `/sharedLinkSetting` | SharedLinkSettingView | 공유 링크 설정 |
| `/tutorial` | TutorialView | 온보딩 가이드 |
| `/ossLicenses` | OssLicensesView | 오픈소스 라이선스 |

## Bottom Navigation 탭
1. **My Folder** (`MyFolderPage`) — 폴더 목록
2. **Explore** (`LocalExplorePage`) — 전체 링크 탐색
3. **My Page** (`MyPage`) — 설정/프로필

## 주요 파일
- `lib/routes.dart` — 라우트 정의
- `lib/ui/view/home_view.dart` — 메인 Home + Bottom Nav
- `lib/cubits/home_view_cubit.dart` — 탭 인덱스 상태
- `lib/cubits/home_second_view_cubit.dart` — 보조 네비게이션

## 위젯 라이브러리 (`lib/ui/widget/`)

### 다이얼로그
- `bottom_dialog.dart`, `center_dialog.dart`, `delete_share_folder_dialog.dart`

### 버튼
- `upload_button.dart` — 플로팅 업로드 버튼
- `bottom_sheet_button.dart`

### 링크
- `link_hero.dart` — Hero 애니메이션
- `link_slidable_widget.dart` — 스와이프 액션 (삭제/이동)

### 레이아웃
- `scaffold_with_stack_widget.dart`, `custom_reorderable_list_view.dart`
- `custom_header_delegate.dart`

### 유틸리티
- `loading.dart`, `bottom_toast.dart`, `only_back_app_bar.dart`
- `text/custom_font.dart` — 커스텀 폰트 (Pretendard, Roboto)

## 의존성
- `flutter_screenutil: ^5.9.0` — 반응형 사이즈
- `flutter_svg: ^2.0.6`
- `cached_network_image: ^3.3.1`
- `carousel_slider: ^5.0.0`
- `flutter_slidable: ^4.0.3`
- `lottie` — 애니메이션

## 수정 시 주의사항
- 모달 라우트: 커스텀 페이지 전환 애니메이션 사용
- 테마: Light 모드만 지원 (Primary: primary600)
- `flutter_screenutil` 초기화: 최상위 위젯에서 설정
- 위젯 37개 파일 — 재사용 컴포넌트 먼저 확인 후 새로 만들기
