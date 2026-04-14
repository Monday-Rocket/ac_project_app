---
name: app-folder-management
description: Flutter 앱 폴더 CRUD — 생성/이름변경/삭제, 미분류 폴더, 링크 카운트
type: feature
project: ac_project_app
tier: core
---

# 폴더 관리 (Folder Management)

## 개요
링크를 분류하는 폴더 시스템. 미분류 기본 폴더, 폴더별 링크 카운트, 검색, 썸네일 관리.

## 주요 파일
- `lib/cubits/folders/local_folders_cubit.dart` — 폴더 CRUD + 필터 + 카운트
- `lib/provider/local/local_folder_repository.dart` — SQLite 폴더 CRUD
- `lib/ui/page/my_folder/my_folder_page.dart` — 폴더 목록 UI
- `lib/ui/widget/add_folder/show_add_folder_dialog.dart` — 폴더 생성 다이얼로그
- `lib/ui/widget/rename_folder/show_rename_folder_dialog.dart` — 이름 변경 다이얼로그
- `lib/models/local/local_folder.dart` — 폴더 데이터 모델

## 데이터 모델
```dart
class LocalFolder {
  int? id;
  String name;
  String thumbnail;     // 첫 링크의 이미지
  bool isClassified;    // false = 미분류 폴더
  DateTime createdAt;
  DateTime updatedAt;
}
```

## 핵심 로직
- 미분류 폴더: DB 초기화 시 자동 생성 (`is_classified: false`)
- 폴더 삭제: 하위 링크 cascading delete
- 썸네일: 폴더 내 첫 번째 링크 이미지 자동 할당
- 링크 카운트: 폴더별 저장된 링크 수 표시

## 관련 Cubits
- `get_selected_folder_cubit.dart` — 현재 선택된 폴더 추적
- `folder_name_cubit.dart` — 폴더 이름 입력 상태
- `folder_visible_cubit.dart` — 폴더 표시/숨김 토글

## 수정 시 주의사항
- 미분류 폴더는 삭제 불가 (UI에서 숨김)
- 폴더 구조: 확장프로그램은 계층(parent_id) 지원하지만, 앱은 flat 구조
- 앱↔확장프로그램 동기화 시 폴더 구조 차이 주의
