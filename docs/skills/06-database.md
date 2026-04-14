---
name: app-database
description: Flutter 앱 SQLite 로컬 DB — schema, 인덱스, 마이그레이션, 트랜잭션
type: feature
project: ac_project_app
tier: core
---

# 로컬 데이터베이스 (SQLite Database)

## 개요
Offline-first 아키텍처의 핵심. SQLite로 모든 데이터를 로컬 저장, 클라우드는 선택적.

## 주요 파일
- `lib/provider/local/database_helper.dart` — DB 초기화, 스키마, 마이그레이션
- `lib/provider/local/local_link_repository.dart` — 링크 CRUD
- `lib/provider/local/local_folder_repository.dart` — 폴더 CRUD
- `lib/models/local/local_link.dart` — 링크 SQLite 매핑
- `lib/models/local/local_folder.dart` — 폴더 SQLite 매핑
- `lib/models/local/local_model_extensions.dart` — 모델 변환 헬퍼

## 스키마
```sql
CREATE TABLE folder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  thumbnail TEXT DEFAULT '',
  is_classified INTEGER DEFAULT 1,  -- 0=미분류, 1=분류됨
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE link (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  folder_id INTEGER NOT NULL,
  url TEXT NOT NULL,
  title TEXT DEFAULT '',
  image TEXT DEFAULT '',
  describe TEXT DEFAULT '',
  inflow_type TEXT DEFAULT 'manual',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (folder_id) REFERENCES folder(id) ON DELETE CASCADE
);
```

## 인덱스
```sql
CREATE INDEX idx_link_folder_id ON link(folder_id);
CREATE INDEX idx_link_created_at ON link(created_at DESC);
CREATE INDEX idx_link_title ON link(title);
```

## 초기화
- Foreign key constraints 활성화
- 미분류 폴더 자동 생성
- Lazy initialization (첫 접근 시)

## 테스트
- `sqflite_common_ffi` 사용 (데스크톱 환경 테스트)
- 격리된 테스트 DB 인스턴스 지원

## 의존성
- `sqflite: ^2.4.1`
- `sqflite_common_ffi: ^2.3.4+4` (테스트용)
- `path_provider` (DB 파일 경로)

## 수정 시 주의사항
- 스키마 변경 시 `onUpgrade` 마이그레이션 필수
- CASCADE DELETE: 폴더 삭제 시 링크 자동 삭제
- 트랜잭션 사용: 벌크 작업 시 `database.transaction()` 필수
- DB 이름: `linkpool_local.db` (share.db와 별도)
