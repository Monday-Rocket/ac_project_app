---
name: app-cloud-sync
description: Flutter 앱 ↔ Supabase 양방향 동기화 — 초기 업로드, 증분 동기화, ID 매핑
type: feature
project: ac_project_app
tier: pro
---

# 클라우드 동기화 (Cloud Sync)

## 개요
로컬 SQLite 데이터를 Supabase와 양방향 동기화. 확장프로그램과 동일 스키마 공유.

## 주요 파일
- `lib/provider/sync/sync_repository.dart` — 동기화 전체 로직

## 동기화 단계

### 1. 초기 업로드
```
1. 서버에 기존 데이터 있는지 확인
2. 없으면: 로컬 폴더/링크 전부 업로드
3. 로컬 ID → UUID 매핑 저장 (SharedPreferences)
```

### 2. 증분 동기화 (Pull & Push)
```
Pull: last_sync_at 이후 서버 변경사항 → 로컬 반영
Push: last_sync_at 이후 로컬 변경사항 → 서버 반영
충돌: updated_at 비교, last-write-wins
```

## ID 매핑 (SharedPreferences)
```
sync_folder_map: { localId: serverUUID }
sync_link_map: { localId: serverUUID }
sync_last_at: ISO timestamp
```

## Supabase 테이블
```sql
folders (id UUID, user_id, client_id INT, parent_id UUID, name, thumbnail, is_classified, created_at, updated_at, deleted_at)
links   (id UUID, user_id, client_id INT, folder_id UUID, url, title, image, describe, inflow_type, created_at, updated_at, deleted_at)
```
- `deleted_at`: Soft delete (동기화 시 삭제 전파)

## 배치 처리
- 링크 50개 단위로 업로드

## 의존성
- `supabase_flutter: ^2.12.2`
- `shared_preferences: ^2.5.3`

## 수정 시 주의사항
- 확장프로그램의 `src/supabase/sync.ts`와 동일 스키마 사용
- Soft delete (`deleted_at`) — 확장프로그램에서 삭제한 항목도 동기화
- ID 매핑 손실 시 중복 데이터 발생 가능 → SharedPreferences 백업 고려
