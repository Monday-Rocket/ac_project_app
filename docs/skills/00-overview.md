---
name: app-overview
description: LinkPool Flutter App 전체 기능 인덱스 및 아키텍처 개요
type: index
project: ac_project_app
---

# LinkPool Flutter App — 기능 스킬 인덱스

## 아키텍처
- **Platform**: Flutter (Android + iOS)
- **State Management**: BLoC/Cubit (flutter_bloc)
- **Local DB**: SQLite (sqflite)
- **Cloud**: Supabase (Auth, Database)
- **DI**: GetIt
- **설계**: Offline-first, Cloud-optional

## 기능 스킬
| # | 스킬 파일 | 기능 |
|---|-----------|------|
| 01 | [authentication](01-authentication.md) | Google/Apple 로그인, Pro 플랜 확인 |
| 02 | [link-management](02-link-management.md) | 링크 CRUD, 검색, 메타데이터, 클립보드 |
| 03 | [folder-management](03-folder-management.md) | 폴더 CRUD, 미분류, 카운트 |
| 04 | [cloud-sync](04-cloud-sync.md) | Supabase 양방향 동기화 |
| 05 | [native-share](05-native-share.md) | 시스템 공유 Intent 수신 |
| 06 | [database](06-database.md) | SQLite 스키마, 인덱스, 마이그레이션 |
| 07 | [ui-navigation](07-ui-navigation.md) | 화면 구조, 라우팅, 위젯 |
| 08 | [state-management](08-state-management.md) | Cubit 패턴, DI, 22개 상태 관리 |
| 09 | [metadata-extraction](09-metadata-extraction.md) | OG 태그 파싱, URL 검증 |

## 프로젝트 구조
```
lib/
├── cubits/    (22 Cubit)
├── models/    (24 모델)
├── provider/  (13 Repository/Service)
├── ui/        (37 위젯 + 14 화면)
├── util/      (14 유틸리티)
├── const/     (색상, 문자열)
├── di/        (GetIt 설정)
└── routes.dart
```

## 확장프로그램과 공유 스키마
- Supabase `folders`, `links` 테이블 동일 구조 사용
- `client_id` (로컬 정수 ID) ↔ `id` (서버 UUID) 매핑
- 동기화 시 동일 스키마로 데이터 교환

## 빌드 & 테스트
```bash
flutter build apk      # Android
flutter build ios       # iOS
flutter test            # 단위 테스트
```

## 의존성 (주요)
supabase_flutter, flutter_bloc, sqflite, get_it, google_sign_in, sign_in_with_apple, dio, cached_network_image, flutter_screenutil
