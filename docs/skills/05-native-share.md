---
name: app-native-share
description: Flutter 앱 네이티브 공유 — 시스템 Share Intent로 링크 수신 및 벌크 저장
type: feature
project: ac_project_app
tier: core
---

# 네이티브 공유 (Native Share Integration)

## 개요
다른 앱에서 "공유" → LinkPool로 링크 수신. 별도 share.db를 통한 네이티브 ↔ Flutter 데이터 전달.

## 주요 파일
- `lib/provider/share_data_provider.dart` — Platform Channel 통신 (getNewLinks, getNewFolders, clearData)
- `lib/provider/local/local_bulk_repository.dart` — 벌크 가져오기 (폴더 생성 + 링크 저장)
- `lib/provider/share_db.dart` — share.db 경로 관리 (Android/iOS 분리)

## 아키텍처
```
[다른 앱] → [시스템 Share Intent]
   → [네이티브 Share Extension (iOS) / Activity (Android)]
   → [share.db에 저장]
   → [Flutter 앱 시작/resume]
   → [share_data_provider로 읽기]
   → [local_bulk_repository로 메인 DB에 저장]
   → [share.db 클리어]
```

## Platform Channel
```dart
// share_data_provider.dart
getNewLinks(): List<Link>       // share.db에서 새 링크 조회
getNewFolders(): List<Folder>   // share.db에서 새 폴더 조회
clearData(): void               // 가져온 후 share.db 클리어
getShareDBUrl(): String         // 플랫폼별 share.db 경로
```

## 벌크 처리 로직
- URL 중복 체크 후 저장
- 폴더명 매칭으로 자동 분류
- 매칭 안 되면 미분류 폴더로
- 폴더 썸네일: 첫 링크 이미지 자동 할당

## 의존성
- Platform Channel: `share_data_provider`
- SQLite: `share.db` (별도 DB)

## 수정 시 주의사항
- Android/iOS share.db 경로가 다름 — `getShareDBUrl()` 참조
- 네이티브 코드 수정 필요 시: Android `MainActivity.kt` / iOS `ShareExtension`
- 앱이 종료 상태에서 공유 시 cold start 고려
