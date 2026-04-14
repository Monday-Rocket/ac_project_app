---
name: app-link-management
description: Flutter 앱 링크 CRUD — 저장/검색/편집/삭제, 메타데이터 추출, 클립보드 감지
type: feature
project: ac_project_app
tier: core
---

# 링크 관리 (Link Management)

## 개요
링크 저장(수동/공유/클립보드), 메타데이터 자동 추출, 검색, 편집, 삭제. 페이지네이션 지원.

## 주요 파일

### 업로드
- `lib/cubits/links/local_upload_link_cubit.dart` — 링크 생성 로직 (URL 검증, 메타데이터, 중복 체크)
- `lib/ui/view/upload_view.dart` — 업로드 UI (폴더 선택, URL 입력, 메타데이터 미리보기)
- `lib/util/url_loader.dart` — OG 메타데이터 추출 (`metadata_fetch` 패키지)
- `lib/util/url_valid.dart` — URL 유효성 검사 (HTTP GET 200 확인)

### 목록 / 탐색
- `lib/cubits/links/local_links_cubit.dart` — 전체 링크 목록 + 페이지네이션 (20개/페이지)
- `lib/ui/page/home/local_explore_page.dart` — 전체 링크 탐색 UI
- `lib/cubits/links/local_links_from_folder_cubit.dart` — 폴더별 링크 필터
- `lib/ui/view/links/my_link_view.dart` — 폴더 내 링크 목록

### 검색
- `lib/cubits/home/local_search_links_cubit.dart` — 제목/URL/설명 검색 + 페이지네이션
- `lib/ui/view/links/search_view.dart` — 검색 UI

### 상세 / 편집
- `lib/cubits/links/local_detail_edit_cubit.dart` — 링크 편집/삭제/이동
- `lib/ui/view/links/link_detail_view.dart` — 상세 보기 + 편집 모드

### Repository
- `lib/provider/local/local_link_repository.dart` — SQLite 링크 CRUD

## 데이터 모델
```dart
// lib/models/local/local_link.dart
class LocalLink {
  int? id;
  int folderId;
  String url;
  String title;
  String image;       // OG image
  String describe;    // OG description
  String inflowType;  // 'manual' | 'share' | 'clipboard'
  DateTime createdAt;
  DateTime updatedAt;
}
```

## 핵심 로직
- 클립보드 감지: 앱 resume 시 클립보드 URL 자동 감지 → 저장 제안
- URL 검증: `Uri.parse(url).isAbsolute` + HTTP GET 200 확인
- 중복 방지: URL 기준 중복 체크
- 메타데이터: `metadata_fetch` 패키지 (boring-km 포크)

## 의존성
- `metadata_fetch` (custom git fork)
- `dio: ^5.4.1`
- `cached_network_image: ^3.3.1`
- `sqflite: ^2.4.1`

## 수정 시 주의사항
- 페이지네이션: 20개 단위, 무한 스크롤
- `inflowType`으로 저장 경로 추적 (수동/공유/클립보드)
- 메타데이터 추출 실패 시 URL만으로 저장 가능
