# LinkPool 앱 Pro 전환 로드맵

> 작성일: 2026-04-21
> 문서 성격: **handoff 문서** — 세션 초기화 후 새 세션에서 이 문서만 읽고
>            즉시 구현을 이어갈 수 있도록 작성됨.
> 관련 문서:
> - `ac_project_app/docs/DEVELOPMENT_SETUP.md` — 로컬 개발 환경 셋업
> - `linkpool-chrome-extension/docs/PRO_FEATURES.md` — 크롬 확장 쪽 Pro 기능 설계
> - `linkpool-chrome-extension/docs/PAYMENT_PLAN.md` — 결제 플랜 (RevenueCat)
> - `linkpool-chrome-extension/docs/PROGRESS.md` — 크롬 확장 진행 현황
> - `linkpool-chrome-extension/docs/REMAINING_TASKS.md` — 남은 작업 목록
> - `linkpool-chrome-extension/docs/APPLE_LOGIN.md` — **크롬 확장 Apple 로그인 추가 (P2 선행 조건)**

---

## Quick Resume (세션 재개 시 이것부터)

1. **현재 진행 상황**: 전부 pending. 구현 시작 전 상태. 모든 설계/정책은 인터뷰로 확정됨.
2. **다음 할 일**: **Task #11 (P0 — 공유 폴더 코드 잔재 제거)** 부터 시작. 대상 파일은 섹션 10.1 참조.
3. **환경 전제**:
   - Flutter 3.41.6 기반 (최근 pub get 이슈는 해소됨)
   - Supabase 인프라 셋업 완료 (Auth, DB, 3개 migration 적용 상태)
   - Apple OAuth 설정 완료 (iOS 앱 + Supabase provider 등록). 크롬 확장은 이걸 재사용.
   - 프로덕션에 실유저 Supabase 데이터 0건 — migration 자유도 최대
   - git은 **개인 계정**으로만 사용 (이 프로젝트 전용 정책)
4. **Phase 순서**: P0 → P1 → P2. P1은 스키마/레포지토리부터(#12 → #13 → #17), 그 다음 UI (#14 → #15 → #16).
5. **막힐 때 참조**:
   - 왜 이렇게 결정했는가? → 섹션 9 (결정 이력 요약)
   - 현재 코드 어디에 뭐가 있나? → 섹션 10 (코드베이스 스냅샷)
   - 추가 결정 필요한 사항 있나? → 섹션 11 (열린 질문)
   - 크롬 확장 측 작업은? → `linkpool-chrome-extension/docs/APPLE_LOGIN.md`
6. **태스크 ID 매칭표**: 섹션 8

---

## 0. 배경 & 현재 상태

### 0.1 제품 방향
- LinkPool은 **개인용 링크 관리 앱** (공유 폴더 개념은 폐기됨)
- 모바일 앱(`ac_project_app`, Flutter) + 크롬 확장(`linkpool-chrome-extension`, React/Vite) 양쪽 플랫폼
- **수익화 전략**: Pro 구독 — 크롬과 앱 사이 데이터 동기화/백업 + AI 자동 분류 + 깨진 링크 체크
- 결제: RevenueCat 기반 인앱 결제 (iOS/Android). 크롬 확장은 결제 UI 없이 "앱에서 결제" 안내만

### 0.2 Supabase 인프라 현황
- **이미 Supabase 도입 완료**: `main.dart`에서 초기화, `supabase_flutter ^2.12.2` 의존성
- **Auth (Google/Apple) 로그인**: `lib/provider/auth/auth_repository.dart` — Supabase `signInWithIdToken` 사용
- **실유저 데이터 0건**: 현재 프로덕션 앱은 오프라인(SQLite)만 사용. Supabase에 아직 실사용자 CRUD 데이터 없음. 즉 **migration 자유도 매우 높음**
- 기존 3개 migration: `profiles`(plan, plan_expires_at), `folders`, `links` 테이블 + RLS + `deleted_at` 컬럼 존재

### 0.3 앱의 현재 기능 상태
- **Pro 상태 읽기**: `AuthRepository.getPlan()` — `plan` + `plan_expires_at` 조회, 만료 시 자동 free 강등
- **isPro 게이팅**: `AuthCubit.isPro` getter 존재, MyPage에 "Pro" 배지 표시. 실제 기능 차단은 미구현
- **SyncRepository 초안 존재**: `initialUpload`, `incrementalSync` 구현되어 있음. 단 아직 호출 지점 없음. 현재 설계와 맞지 않아 **거의 전면 재작성 예정**
- **깨진 링크 체크**: 이미 클라이언트(앱 내부 HTTP HEAD)로 구현됨. 단 Pro 게이팅 없음
- **AI 자동 분류, 내보내기**: 미구현 (AI 분류는 Phase P2 이후 별도 작업, 내보내기는 앱 스코프 아님)
- **공유 폴더**: 프로덕션엔 제거된 상태지만 develop 브랜치에 **코드 잔재 남아있음** (파일 5개, import/참조 여러 군데) → Phase P0에서 제거

### 0.4 폴더 구조 방향성
- **현재**: 앱은 flat 폴더 (최상위 1뎁스만). SQLite `folder` 테이블에 `parent_id` 없음
- **크롬 확장**: 중첩 폴더 이미 지원. 크롬 북마크 가져오기 기능의 전제조건
- **결정**: 앱도 **무제한 깊이 중첩 폴더 지원**. 타겟 Pro 유저(북마크 파워유저)의 계층 구조를 손실 없이 보존해야 함

---

## 1. Phase 구조 및 의존 관계

```
P0: 공유 폴더 코드 잔재 제거 ──┐
                              │
P1: 중첩 폴더 지원 ────────────┼── P2: 백업/복구 + Pro CRUD 원격 쓰기
 ├─ 로컬 SQLite 스키마 v2     │    ├─ Supabase migration 004
 ├─ 레포지토리 계층 조회 확장 │    ├─ SyncRepository 리팩토링
 ├─ UI 전면 개편             │    ├─ AuthCubit plan 캐싱/감지
 └─ 미분류 시스템화          │    ├─ Pro CRUD 원격 쓰기 훅
                              │    ├─ dirty 플래그 보정 백업
                              │    ├─ MyPage 백업/복구 UI
                              │    └─ 자동 복구 팝업
                              │
                              └── (결제 연동은 별도 작업, 이 로드맵 밖)
```

**순서가 중요한 이유:**
- P0 선행: P1 UI 설계 시 공유 폴더를 신경 쓸 필요가 없어짐
- P1 선행: P2의 복구 로직이 "크롬 중첩 구조를 앱에서도 자연스럽게 받는 것"을 전제로 함
- P2 진행 시 P1의 parent_id 필드가 원격 스키마와 1:1로 맞아서 복구가 단순

---

## 2. Phase P0 — 공유 폴더 코드 잔재 제거

### 2.1 제거 대상 파일 (완전 삭제)
- `lib/ui/widget/dialog/delete_share_folder_dialog.dart`
- `lib/ui/view/links/shared_link_setting_view.dart`
- 관련 delegate_admin 관련 파일이 있다면 함께

### 2.2 수정 대상 파일 (공유 폴더 분기 제거)
- `lib/ui/widget/dialog/bottom_dialog.dart` — 공유 폴더 관련 분기/메뉴 약 12곳
- `lib/ui/page/my_folder/my_folder_page.dart` — 공유 폴더 탭/분기 약 6곳
- `lib/ui/view/links/my_link_view.dart` — 공유 폴더 참조 1곳
- `lib/routes.dart` — `sharedLinkSetting`, `delegateAdmin` 등 라우트 제거
- 관련 라우트 상수, import, dead code

### 2.3 확인 포인트
- 공유 폴더 관련 cubit/모델(`SharedFolder`, `DetailUser`, `DelegateAdmin` 등)이 있다면 사용처 확인 후 제거
- `share_data_provider.dart`, `share_db.dart`는 **iOS Share Extension용**이므로 건드리지 말 것 (헷갈리기 쉬움)
- 공유 폴더와 별개로 존재하는 "링크 공유(카카오톡/링크 URL 공유)"는 이미 제거됨 (`0f5053af`, `855c941a` 커밋)
- 리팩토링 후 `flutter analyze` 에러 0개 확인

### 2.4 커밋 메시지 예시
```
chore: 공유 폴더 관련 코드 잔재 제거

프로덕션엔 이미 제거된 공유 폴더 기능의 코드가 develop 브랜치에
남아있던 것을 정리. 개인 전용 앱 방향성에 맞춤.
```

---

## 3. Phase P1 — 중첩 폴더 지원

### 3.1 타겟 유저 & 설계 원칙
- **타겟**: PC에서 크롬 북마크를 **세세한 계층으로** 관리하는 파워유저. 이 구조를 모바일에서도 손실 없이 보고 싶어함
- **원칙 1**: 무제한 깊이 허용. UI는 스크롤/화면 이동으로 해결
- **원칙 2**: 모바일 UX 관례 존중 — 기본 탐색은 드릴다운(Finder 스타일). 전체 조망은 별도 모달
- **원칙 3**: 폴더 선택 UX는 **앱에서 가장 자주 쓰는 동작**이므로 가장 큰 투자. 검색+최근+드릴다운 하이브리드
- **원칙 4**: 미분류 폴더는 시스템 폴더로 고정 — 크롬 확장과 정책 일치

### 3.2 로컬 SQLite 스키마 v2

**현재 (v1)**
```sql
CREATE TABLE folder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  thumbnail TEXT,
  is_classified INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**v2로 변경**
```sql
ALTER TABLE folder ADD COLUMN parent_id INTEGER
  REFERENCES folder(id) ON DELETE CASCADE;

CREATE INDEX idx_folder_parent_id ON folder(parent_id);
```

- `parent_id`는 nullable. `NULL` = 최상위
- 기존 모든 폴더는 마이그레이션 시 `parent_id=NULL`로 유지됨
- FK CASCADE로 상위 폴더 삭제 시 하위 폴더 + 그 안의 링크까지 연쇄 삭제
- `_dbVersion = 2`로 변경, `_onUpgrade`에 ALTER TABLE 로직 추가

### 3.3 LocalFolder 모델 변경
```dart
class LocalFolder {
  final int? id;
  final int? parentId;    // 신규
  final String name;
  final String? thumbnail;
  final bool isClassified;
  final String createdAt;
  final String updatedAt;
  final int? linksCount;          // 기존 (직접 담긴 링크 수)
  // final int? linksCountRecursive;  // 필요 시 추가 (하위 포함 링크 수)
}
```

### 3.4 LocalFolderRepository 확장 메서드

```dart
// 최상위 폴더들 (parent_id IS NULL)
Future<List<LocalFolder>> getRootFolders();

// 특정 폴더의 직계 자식
Future<List<LocalFolder>> getChildFolders(int parentId);

// 재귀: 특정 폴더의 모든 후손 (링크 카운트 계산, 검색 등에 사용)
Future<List<LocalFolder>> getAllDescendants(int folderId);

// 브레드크럼: 루트부터 해당 폴더까지의 경로
Future<List<LocalFolder>> getBreadcrumb(int folderId);

// 재귀 링크 카운트: 각 폴더의 "자기 + 모든 후손" 링크 수
// WITH RECURSIVE 사용
Future<Map<int, int>> getRecursiveLinkCounts();

// 폴더 이동 (부모 변경)
// 순환 참조 방지: newParentId가 folderId의 후손이면 실패
Future<bool> moveFolder(int folderId, int? newParentId);
```

**재귀 CTE 예시 (링크 카운트):**
```sql
WITH RECURSIVE subtree(id, root) AS (
  SELECT id, id FROM folder
  UNION ALL
  SELECT f.id, s.root FROM folder f
  JOIN subtree s ON f.parent_id = s.id
)
SELECT s.root AS folder_id, COUNT(l.id) AS total
FROM subtree s
LEFT JOIN link l ON l.folder_id = s.id
GROUP BY s.root;
```

### 3.5 UI 변경

#### 3.5.1 폴더 리스트 화면 (`my_folder_page.dart` 등)
- **기본 탐색**: Finder 스타일 드릴다운
  - 상단 브레드크럼 (깊어지면 중간 `…` 생략)
  - 하위 폴더 섹션 → 현재 폴더의 직접 링크 섹션 동시 표시
  - 각 폴더에 **재귀 링크 카운트** 표시
- **전체 트리 모달**: 상단 아이콘으로 진입
  - 펼침/접음 가능한 트리 뷰
  - 노드 탭 시 해당 폴더로 직접 점프 (모달 닫힘)

#### 3.5.2 폴더 탐색 화면 — 하위 폴더 + 직접 링크 동시 표시
```
┌─────────────────────────┐
│ ← 일 > 개발             │
├─ 하위 폴더 ───────────── │
│ 📁 React (12)           │
│ 📁 Vue (8)              │
├─ 이 폴더의 링크 ───────── │
│ 🔗 link1                │
│ 🔗 link2                │
└─────────────────────────┘
```
- 빈 섹션은 숨김 처리 (말단 폴더 → 하위 폴더 섹션 숨김; 중간 폴더 → 직접 링크 없으면 해당 섹션 숨김)

#### 3.5.3 폴더 선택 모달 (링크 저장 / 링크 이동 / 폴더 이동 모두 재사용)
```
┌─ 폴더 선택 ─────────────┐
│ [🔍 폴더 검색...]       │
├─ 최근 사용 ──────────── │
│ 📁 React   (일 > 개발)  │
│ 📁 Hooks   (일 > 개발)  │
├─ 전체 ───────────────── │
│ 📁 일           >       │   ← 드릴다운 진입
│ 📁 개인         >       │
│ 📁 미분류               │
└─────────────────────────┘
```
- **검색**: 폴더명 substring 매칭 + 경로 표시
- **최근 사용**: 최근 링크 저장/이동 대상 폴더 3~5개. `SharedPreferences`에 recent_folder_ids 큐 유지
- **전체**: 드릴다운. 현재 뎁스의 폴더 + `>` 버튼으로 하위 진입

#### 3.5.4 폴더 옵션 메뉴
- **이동** 액션 추가 → 위 모달로 대상 부모 선택
- **순환 참조 방지**: 자기 자신이나 자기 하위 폴더를 부모로 선택 불가 (UI에서 disable + repository에서 검증)
- 미분류 폴더는 옵션 메뉴에서 "이동", "삭제", "하위 폴더 만들기" 액션 자체가 노출되지 않음

### 3.6 미분류 폴더 정책
- **위치**: 최상위 고정 (`parent_id = NULL` 강제)
- **이동**: 불가
- **삭제**: 불가
- **중첩**: 미분류 아래에 폴더 생성 불가
- **이름 변경**: 불가 (필요 시 확장 가능하지만 첫 릴리스에선 고정)
- **개수**: 한 유저당 1개 (로컬 + 원격 공통)
- **식별 방법**: `is_classified = false` 플래그
- **크롬 확장과 정책 완전 일치** (크롬 확장도 같은 규칙 구현되어 있어야 함)

### 3.7 P1 태스크 목록
- **#11** 공유 폴더 코드 잔재 제거 (P0)
- **#12** 로컬 SQLite 스키마 v2 + 모델 확장
- **#13** LocalFolderRepository 계층 조회 메서드 확장
- **#14** 폴더 리스트 UI — 드릴다운 + 트리 모달
- **#15** 폴더 선택 모달 (검색 + 최근 + 드릴다운)
- **#16** 폴더 옵션 메뉴에 "이동" 추가
- **#17** 미분류 폴더 시스템 폴더화

### 3.8 구현 순서 제안
1. #11 (P0 선행)
2. #12 (스키마 + 모델)
3. #13 (레포지토리)
4. #17 (미분류 시스템화 — 다른 UI 작업에 영향 주므로 먼저)
5. #14 (폴더 리스트 UI)
6. #15 (폴더 선택 모달)
7. #16 (폴더 이동)

---

## 4. Phase P2 — 백업/복구 + Pro CRUD 원격 쓰기

### 4.1 모델 개요

**핵심 원칙**
- 로컬 SQLite = 진실의 원천 (Free/Pro 공통)
- **Pro 유저**: CRUD 시 로컬 + 원격에 **동시에** fire-and-forget 쓰기
- 원격 쓰기 실패 시 `lp_remote_dirty` 플래그 ON → 나중에 full replace 백업으로 보정
- **주기적 자동 백업은 없음** — dirty일 때만 보정
- 백업/복구는 **Pro 전용**
- 삭제는 **hard delete로 통일** (양쪽 모두)
- 기기 간 Realtime 동기화, 오프라인 큐, 양방향 충돌 해결 모두 **없음**

### 4.2 트리거 매트릭스

| 이벤트 | 조건 | 동작 |
|---|---|---|
| Pro 유저 CRUD | `isPro == true` (로그인 + Pro) | 로컬 쓰기 + 원격 fire-and-forget. 실패 시 dirty ON |
| 로그아웃 상태 CRUD | - | 로컬 쓰기만. dirty 세팅 안 함 (원격과 무관한 상태) |
| 앱 시작 시 | Pro + dirty | `backupToRemote()` full replace → dirty OFF |
| 포그라운드 복귀 (`AppLifecycleState.resumed`) | Pro + dirty | 위와 동일 |
| Free → Pro 전환 감지 | plan 캐시 비교 | `backupToRemote()` (초기 업로드) |
| Pro → Free 전환 감지 | plan 캐시 비교 | `restoreFromRemote()` → `purgeRemote()` |
| Pro 유저 신규 기기 로그인 | 원격 백업 존재 + 로컬 links 개수 0 | 복구 팝업 (사용자 Yes → `restoreFromRemote()`) |
| MyPage "지금 백업" | Pro 유저에게만 노출 | `backupToRemote()` |
| MyPage "백업에서 복원" | Pro 유저에게만 노출 | 덮어쓰기 경고 → `restoreFromRemote()` |
| 로그아웃 | - | 추가 백업 없음 (평상시 이미 원격 반영됨) |

### 4.3 Supabase Migration 004

현재 원격 스키마의 문제:
- `client_id` 컬럼이 nullable → 복합 유니크 걸기 애매
- `(user_id, client_id)` 복합 유니크 제약 없음 → 개별 upsert 충돌 감지 불가
- `deleted_at` 컬럼 존재 → hard delete 통일 방침과 충돌
- 미분류 폴더의 유저당 1개 제약 없음

**Migration 004 내용 예시:**
```sql
-- 004_pro_sync_schema_cleanup.sql

-- 1) client_id NOT NULL + 복합 유니크
ALTER TABLE folders ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE folders ADD CONSTRAINT folders_user_client_unique
  UNIQUE (user_id, client_id);

ALTER TABLE links ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE links ADD CONSTRAINT links_user_client_unique
  UNIQUE (user_id, client_id);

-- 2) deleted_at 제거 (hard delete 통일)
ALTER TABLE folders DROP COLUMN deleted_at;
ALTER TABLE links DROP COLUMN deleted_at;

-- 3) 미분류 폴더 유저당 1개 partial unique
CREATE UNIQUE INDEX folders_one_unclassified_per_user
  ON folders (user_id) WHERE is_classified = false;

-- 4) parent_id는 유지 (앱도 중첩 지원으로 확정됨)
--    현재 (006 이후 결정) parent_id 그대로 둠
```

**주의:** 이 migration은 실유저 데이터 0건 상태에서 실행해야 안전. 실행 전 Supabase Studio에서 folders/links 데이터 건수 재확인 필요.

### 4.4 Pro 상태 캐싱 & 만료 감지 (AuthCubit)

```dart
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? plan;              // 'free' | 'pro'
  final DateTime? planExpiresAt;
  final String? errorMessage;

  bool get isPro {
    if (plan != 'pro') return false;
    if (planExpiresAt == null) return true;
    return planExpiresAt!.isAfter(DateTime.now());
  }
}
```

**트리거**
- 앱 시작 시: `getPlan()` → `state` 갱신 + 이전 캐시(`SharedPreferences.lp_cached_plan`)와 비교
- `AppLifecycleState.resumed` 시: `refreshPlan()` 자동 호출
- **free→pro 감지**: `backupToRemote()` (초기 업로드) 트리거
- **pro→free 감지**: `restoreFromRemote()` 후 `purgeRemote()` 트리거
- 성공 후 `lp_cached_plan` 갱신

### 4.5 SyncRepository 재설계

**제거할 것 (기존 초안)**
- `initialUpload()` (→ `backupToRemote()`로 교체)
- `incrementalSync()`, `_pullFolders`, `_pullLinks`, `_pushFolders`, `_pushLinks`
- `_folderMap`, `_linkMap` 관리 (client_id ↔ uuid 매핑은 원격 `(user_id, client_id)` 복합 유니크로 처리)
- `deleted_at` 관련 분기 (soft delete 폐기)

**새 API**
```dart
class SyncRepository {
  // 모든 원격 쓰기는 이 래퍼로
  // 요청 전 dirty=true (optimistic — 앱 강제종료 대비)
  // 성공 시 dirty=false
  // 실패 시 dirty 유지
  Future<void> remoteWrite(Future<void> Function() operation);

  // 개별 row 원격 쓰기 (remoteWrite 경유)
  Future<void> upsertFolderRemote(LocalFolder folder);
  Future<void> upsertLinkRemote(LocalLink link);
  Future<void> deleteFolderRemote(int localFolderId);
  Future<void> deleteLinkRemote(int localLinkId);

  // 전체 백업 — Pro 전환, dirty 보정, 수동 백업용
  // 항상 full replace (기존 원격 folders/links 전부 DELETE + 로컬 전체 INSERT)
  // 한 트랜잭션으로 묶어 잔재 자동 청소
  // 미분류 폴더는 is_classified=false + ON CONFLICT (user_id) WHERE is_classified=false DO UPDATE
  Future<bool> backupToRemote();

  // 원격 데이터 존재 여부 (자동 복구 팝업 조건 체크)
  Future<bool> hasRemoteBackup();

  // 전체 복구 — 2단계
  //   1단계: 원격 folders/links 전체를 메모리로 다운로드
  //   2단계: 성공 시 로컬 SQLite 트랜잭션으로 기존 데이터 삭제 + 새 데이터 삽입
  //          마지막에 sqlite_sequence UPDATE로 auto-increment 시퀀스 보정
  Future<void> restoreFromRemote();

  // Pro → Free 전환 시 원격 전체 삭제
  // 실패해도 다음 백업이 full replace이므로 자동 청소됨
  Future<void> purgeRemote();

  // 상태 확인
  Future<DateTime?> getLastBackupAt();
  Future<bool> isDirty();
}
```

### 4.6 CRUD 원격 쓰기 훅 (LocalFolderRepository / LocalLinkRepository)

- `insert`/`update`/`delete` 경로 끝에 `AuthCubit.state.isPro`가 true이면 `SyncRepository.remoteWrite()` fire-and-forget 호출
- 호출자(UI/Cubit)는 원격 쓰기 성공 여부 신경 안 씀
- 실패해도 앱 동작엔 영향 없음 (dirty 플래그가 나중에 보정)

### 4.7 중복 실행 방지
- `SyncRepository._isBackingUp: bool` 내부 플래그
- 백업 시작 시 true, 종료 시 false
- 이미 실행 중이면 새 호출은 no-op

### 4.8 복구 시 SQLite 시퀀스 보정
```sql
UPDATE sqlite_sequence
  SET seq = (SELECT COALESCE(MAX(id), 0) FROM folder)
  WHERE name = 'folder';
UPDATE sqlite_sequence
  SET seq = (SELECT COALESCE(MAX(id), 0) FROM link)
  WHERE name = 'link';
```

이게 빠지면 복구 후 신규 insert 시 id 충돌 발생.

### 4.9 자동 복구 팝업 조건
- Pro 로그인 직후 + `hasRemoteBackup() == true` + 로컬 `links.count() == 0`
- 세 조건 모두 만족 시: `"백업에서 복원하시겠습니까?"` 다이얼로그
- 그 외: 팝업 없이 조용히 진행 (기기 변경 등은 MyPage 수동 복구 버튼으로)

### 4.10 수동 복구 UX
- 로컬에 데이터 있음 → `"⚠ 현재 기기의 데이터가 삭제되고 백업으로 덮어써집니다."` 경고
- 원격 백업 없음 → `"백업된 데이터가 없습니다"` 토스트 후 종료

### 4.11 오프라인 처리
- 자동 백업이 네트워크 오류로 실패 → 조용히 skip, `lp_last_backup_at` 갱신 안 함, dirty 유지
- 다음 트리거 때 자연스럽게 재시도

### 4.12 P2 태스크 목록
- **#4** Supabase migration 004 (스키마 정리)
- **#5** SyncRepository 리팩토링
- **#6** AuthCubit plan 캐싱 + 만료 감지
- **#7** Pro CRUD 원격 쓰기 훅
- **#8** dirty 플래그 보정 백업
- **#9** MyPage 백업/복구 UI
- **#10** 자동 복구 팝업

### 4.13 P2 구현 순서
1. #4 (Supabase migration — 실유저 0건 확인 후 실행)
2. #5 (SyncRepository 전면 재작성)
3. #6 (AuthCubit plan 감지)
4. #7 (CRUD 원격 쓰기 훅)
5. #8 (dirty 보정 경로)
6. #9 (MyPage UI)
7. #10 (자동 복구 팝업)

---

## 5. 결제 붙인 이후 보강 필요 항목

P2까지 완성되면 결제(RevenueCat) 연동이 가능해지는데, 결제 붙인 이후에 추가로 손볼 항목:

### 5.1 구매 성공 콜백에서 `AuthCubit.refreshPlan()` 호출
- 현재는 앱 시작/포그라운드 복귀 시에만 plan 재조회
- 구매 직후 앱이 계속 포그라운드에 있으면 plan 변화 감지가 지연됨
- 구매 플로우에서 Supabase webhook 처리 완료 확인 후 명시적으로 `refreshPlan()` 호출

### 5.2 Pro 만료 타이밍 정밀화
- 현재: 앱 시작 시 + `AppLifecycleState.resumed` 시에만 만료 체크
- 앱이 포그라운드에 계속 떠 있는데 `plan_expires_at`이 그 사이 지나가면 감지 지연
- 보강 옵션:
  - RevenueCat webhook에서 만료 이벤트 수신 → Supabase에서 profiles.plan 즉시 갱신
  - 앱 쪽은 `planExpiresAt`까지 남은 시간을 Timer로 예약 → 그 시점에 `refreshPlan()` 자동 호출

### 5.3 구독 상태 변경 중 발생하는 CRUD 처리
- 만료 직후 ~ 다음 앱 시작 전 사이에 CRUD가 일어나면 원격 쓰기가 일어날 수 있음
- 현재 설계에선 `isPro` getter가 `planExpiresAt이 미래`를 함께 체크하므로 **만료 시각이 지나면 자동 false 전환** → 원격 쓰기 자연 skip
- 결제 이후 실제 테스트로 검증 필요

### 5.4 RevenueCat 웹훅과 profiles.plan 일관성
- webhook이 profiles.plan을 갱신하는 시점과 앱이 `getPlan()`을 호출하는 시점의 타이밍 문제
- webhook 처리 실패 시 fallback (예: 주기적 RevenueCat API 조회)
- 구현은 `linkpool-chrome-extension/supabase/functions/revenuecat-webhook/`에서

### 5.5 구독 만료 시 복구/삭제 실패 대응
- `restoreFromRemote()` 실패 시 사용자는 Pro 데이터를 로컬에 가져오지 못함
- 보강: 실패 플래그를 두고 다음 앱 시작 시 다시 시도하는 로직 (현재는 로그만)
- `purgeRemote()` 실패는 다음 백업이 full replace라 자동 해결

---

## 6. 각 Phase별 의존 가정 및 확인 포인트

### 6.1 P0 실행 전 확인
- `develop` 브랜치가 최신인지
- 공유 폴더 관련 파일이 정말 사용되지 않는지 (라우트 연결, 깊은 import 체인 확인)

### 6.2 P1 실행 전 확인
- P0 완료 (공유 폴더 제거로 UI 레이아웃 단순화된 상태)
- 기존 flat 구조의 공유 폴더 관련 DB 컬럼/모델 잔재 없는지

### 6.3 P2 실행 전 확인
- P1 완료 (로컬 `folder.parent_id` 존재)
- Supabase `folders`/`links` 테이블에 **실유저 데이터 0건** 재확인
- 크롬 확장의 `parent_id` 사용 방식과 일치하는지 (앱과 크롬 양쪽이 같은 규약)
- Supabase Auth에 Google/Apple provider 활성화되어 있는지
- **크롬 확장 Apple 로그인 추가 완료** (Task #18, `linkpool-chrome-extension/docs/APPLE_LOGIN.md` 참조)
  - 앱에서 Apple로 가입한 Pro 유저가 크롬 확장에서도 로그인 가능해야 P2의 양방향 시나리오가 성립

---

## 7. 테스트 전략 (Phase별)

### 7.1 P0
- `flutter analyze` 0 errors
- 앱 실행 후 각 화면 진입 테스트 — 공유 폴더 관련 라우트가 없어졌을 때 다른 화면이 깨지지 않는지

### 7.2 P1
- **스키마 마이그레이션 테스트**: v1 DB가 있는 상태에서 v2로 업그레이드 시 데이터 손실 없는지
- **재귀 CTE 테스트**: 깊이 10 이상 중첩 구조에서 링크 카운트 정확한지, 성능 문제 없는지
- **순환 참조 방지**: 자기 자신/자기 후손을 부모로 지정 시 실패하는지
- **미분류 시스템 폴더**: 이동/삭제/하위 폴더 생성 시도가 모두 차단되는지
- **UI 테스트**: 드릴다운 + 트리 모달 + 폴더 선택 모달 3개 플로우

### 7.3 P2
- **Supabase migration 004 실행 후 RLS 동작**
- **Pro CRUD 원격 쓰기**: 네트워크 끊은 상태에서 CRUD → dirty ON → 네트워크 복구 + 포그라운드 복귀 → 자동 full replace
- **Pro → Free 전환**: 로컬 데이터 유지 + 원격 삭제 확인
- **Free → Pro 전환**: 초기 백업 자동 실행 확인
- **신규 기기 복구**: 로컬 비어있음 + 원격 존재 → 팝업 → 복구 후 SQLite 시퀀스 보정 확인
- **수동 복구**: 로컬에 데이터 있는 상태에서 복구 시 덮어쓰기 경고 확인

---

## 8. 태스크 전체 목록 (TaskCreate ID 매칭)

| ID | Phase | 제목 | 상태 |
|---|---|---|---|
| #11 | P0 | 공유 폴더 코드 잔재 제거 | pending |
| #12 | P1 | 로컬 SQLite 스키마 v2 — 중첩 폴더 | pending |
| #13 | P1 | LocalFolderRepository 계층 조회 메서드 확장 | pending |
| #17 | P1 | 미분류 폴더 시스템 폴더화 | pending |
| #14 | P1 | 폴더 리스트 UI — 드릴다운 + 트리 모달 | pending |
| #15 | P1 | 폴더 선택 모달 (검색 + 최근 + 드릴다운) | pending |
| #16 | P1 | 폴더 옵션 메뉴에 "이동" 추가 | pending |
| #4 | P2 | Supabase schema 정리 (migration 004) | pending |
| #5 | P2 | SyncRepository 리팩토링 (백업/복구 API) | pending |
| #6 | P2 | AuthCubit plan 캐싱 + 만료 감지 | pending |
| #7 | P2 | Pro CRUD 원격 쓰기 훅 | pending |
| #8 | P2 | dirty 플래그 기반 보정 백업 | pending |
| #9 | P2 | MyPage 백업/복구 UI | pending |
| #10 | P2 | 새 기기 자동 복구 팝업 | pending |
| #18 | P2 선행 | 크롬 확장 Apple 로그인 추가 (별도 저장소) | pending |

---

## 9. 결정 이력 요약 (인터뷰로 확정된 정책)

이 문서의 핵심 정책은 모두 인터뷰로 확정됨. 재논의 시 이 섹션을 참조:

### 9.1 P2 (백업/복구) 관련
- **모델**: 로컬 진실의 원천 + Pro CRUD 시 원격 fire-and-forget 동시 쓰기
- **실패 처리**: dirty 플래그 기반 보정 백업 (주기 백업 없음)
- **백업 실패 전략**: 다음 백업 때 다시 full replace (항상 delete+insert 트랜잭션)
- **복구 실패 방어**: 원격 전체 메모리 다운로드 → 로컬 SQLite 트랜잭션 교체
- **로컬 비어있음 판단**: 원격 백업 존재 + 로컬 links 0개 (자동 팝업), 그 외는 수동 복구 버튼
- **오프라인 자동 백업**: 조용히 skip
- **로그아웃 시**: 추가 백업 없음 (평상시 이미 원격 반영됨)
- **Pro 만료 감지**: 앱 시작 + 포그라운드 복귀 시 `getPlan()` + 이전 캐시 비교
- **Pro 상태 캐싱**: 메모리 캐시(AuthCubit), 결제 후엔 구매 콜백에서 `refreshPlan()` 호출
- **로그아웃 상태 CRUD**: 원격 쓰기 skip, dirty 세팅 안 함
- **백업 중복 실행 방지**: `_isBackingUp` 플래그로 동시 1개 보장
- **네트워크 복귀 감지**: `AppLifecycleState.resumed`만 사용 (connectivity_plus 미도입)
- **Pro 만료 감지 정밀도**: 결제 전까진 앱 시작 + resumed 만으로 충분

### 9.2 P1 (중첩 폴더) 관련
- **깊이 제한**: 무제한 (UI는 스크롤/화면 이동으로 대응)
- **탐색 UX**: 드릴다운(기본) + 전체 트리 모달(조망)
- **링크 저장 시 폴더 선택**: 하이브리드 모달 (검색 + 최근 + 드릴다운)
- **폴더 이동**: 옵션 메뉴 + 위 모달 재사용
- **링크 카운트**: 재귀 포함 (재귀 CTE)
- **미분류 폴더**: 시스템 폴더 (최상위 고정, 이동/삭제/중첩 불가, 크롬과 정책 일치)
- **폴더 탐색 화면 표시**: 하위 폴더 섹션 + 직접 링크 섹션 동시 표시
- **미분류 동기화 식별**: `is_classified=false` + partial unique + upsert

### 9.3 제품 방향성 관련
- **앱의 성격**: 개인용 (공유 폴더 개념 제거)
- **타겟 Pro 유저**: PC 북마크 파워유저, 세세한 계층 구조 보존 필수
- **크롬 북마크 가져오기**: 핵심 기능 (초기 1회성 마이그레이션 아님)
- **수익화 우선**: Pro 전환 경로 확보 후 결제 연동

---

## 10. 코드베이스 스냅샷 (2026-04-21 기준)

재개 시 이 섹션을 읽으면 **grep을 다시 돌리지 않고도 바로 Edit을 시작할 수 있다.**
단, 시간이 지나면 라인 번호가 어긋날 수 있으므로 **작업 전 해당 파일을 반드시 Read**로 재확인 후 수정.

### 10.1 P0 — 공유 폴더 잔재 목록 (grep 실측)

**완전 삭제 대상 파일 (2개):**
- `lib/ui/widget/dialog/delete_share_folder_dialog.dart` (약 343줄, `공유폴더` 관련 다이얼로그 2개 + 헬퍼)
- `lib/ui/view/links/shared_link_setting_view.dart` (약 380줄, 공유 폴더 설정 화면)

**수정 대상 파일 (4개):**

| 파일 | 주요 위치 | 수정 내용 |
|---|---|---|
| `lib/routes.dart` | line 19: `sharedLinkSetting` 상수, line 52: `case Routes.sharedLinkSetting` | 라우트 상수 + `onGenerateRoute` 케이스 제거 |
| `lib/ui/page/my_folder/my_folder_page.dart` | line 319, 370, 405, 406, 462, 463 | `isSharedFolder`, `SharedCountText`, `showSharedFolderOptionsDialogFromFolders` 분기 제거. `folder.shared`, `folder.membersCount` 참조 정리 |
| `lib/ui/view/links/my_link_view.dart` | line 243 | "오프라인 모드: 공유 폴더 관련 기능 비활성화" 주석과 관련 dead code 제거 |
| `lib/ui/widget/dialog/bottom_dialog.dart` | line 19(import), 479(showSharedFolderOptionsDialogFromFolders), 485(SharedFolderMenu), 493, 505, 521, 594, 610(showSharedFolderOptionsDialogInShareFolder), 616, 624, 636, 648, 697, 721 | import 제거, `showSharedFolderOptionsDialogFromFolders`/`showSharedFolderOptionsDialogInShareFolder` 함수 2개 삭제, 관련 `SharedFolderMenu` 내부 함수 삭제, `'공유 폴더'` 문자열 분기 제거 |

**호출자 추적 필요:**
- `showSharedFolderOptionsDialogFromFolders`: `my_folder_page.dart:406`에서 호출 → `my_folder_page.dart` 수정 시 함께 정리
- `deleteSharedFolderAdminDialog`: `bottom_dialog.dart:505, 636`에서 호출 → `delete_share_folder_dialog.dart` 삭제와 함께 처리
- `Routes.sharedLinkSetting`: `bottom_dialog.dart:493, 624`에서 `Navigator.pushNamed` 호출 → 위 분기 제거에 포함됨

**관련 모델 필드 (`Folder`):**
- `folder.shared`, `folder.membersCount`, `folder.visible` 등 공유 관련 필드 사용처 확인 필요
- 사용처가 공유 폴더 UI뿐이라면 모델에서도 제거 검토

### 10.2 P2 — 현재 `SyncRepository` 실제 API 목록

`lib/provider/sync/sync_repository.dart` (총 366줄, `_dbVersion = 1` 시절 기반):

**public 메서드:**
- `SyncRepository({required folderRepo, required linkRepo, SupabaseClient? client})` — 생성자
- `Future<String?> getLastSyncAt()` — SharedPreferences `lp_sync_last_at` 읽기
- `Future<bool> isSyncSetup()` — folderMap이 비어있지 않으면 true
- `Future<void> initialUpload()` (line 82) — 폴더 전체 업로드 + 링크 50개씩 배치 업로드. folderMap/linkMap 저장
- `Future<void> incrementalSync()` (line 141) — pull folders → pull links → push folders → push links
- `Future<void> clearSyncData()` (line 360) — SharedPreferences의 folderMap/linkMap/lastSyncAt 제거

**private 메서드:**
- `_getFolderMap`, `_setFolderMap`, `_getLinkMap`, `_setLinkMap`, `_setLastSyncAt`
- `_pullFolders(userId, lastSync, folderMap)` (line 163)
- `_pullLinks(userId, lastSync, folderMap, linkMap)` (line 208)
- `_pushFolders(userId, lastSync, folderMap)` (line 264)
- `_pushLinks(userId, lastSync, folderMap, linkMap)` (line 305)

**새 설계(섹션 4.5)로 교체되는 매핑:**

| 기존 | 교체 |
|---|---|
| `initialUpload()` | `backupToRemote()` (full replace 트랜잭션) |
| `incrementalSync()`, `_pullFolders`, `_pullLinks`, `_pushFolders`, `_pushLinks` | **전부 제거** — 양방향 증분 동기화 폐기 |
| `folderMap`/`linkMap` SharedPreferences 관리 | **전부 제거** — `(user_id, client_id)` 복합 유니크로 해결 |
| `clearSyncData()` | 유지하되 `lp_sync_last_at`만 관리 (새로 `lp_last_backup_at`, `lp_remote_dirty`, `lp_cached_plan` 추가) |
| 없음 | `remoteWrite()`, `upsertFolderRemote()`, `upsertLinkRemote()`, `deleteFolderRemote()`, `deleteLinkRemote()`, `backupToRemote()`, `hasRemoteBackup()`, `restoreFromRemote()`, `purgeRemote()`, `isDirty()` 신규 |

**호출자 추적 (이 Repo를 쓰는 곳):**
- 현재는 호출부 없음. `set_up_get_it.dart`에 DI 등록이 되어 있는지 재확인 필요.
- P2 작업 중 AuthCubit / LocalFolderRepository / LocalLinkRepository에서 호출 추가됨.

### 10.3 P1 — 현재 로컬 SQLite 스키마

`lib/provider/local/database_helper.dart` (총 109줄, `_dbVersion = 1`):

```sql
CREATE TABLE folder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  thumbnail TEXT,
  is_classified INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE link (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  folder_id INTEGER NOT NULL,
  url TEXT NOT NULL,
  title TEXT,
  image TEXT,
  describe TEXT,
  inflow_type TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (folder_id) REFERENCES folder(id) ON DELETE CASCADE
);

CREATE INDEX idx_link_folder_id ON link(folder_id);
CREATE INDEX idx_link_created_at ON link(created_at DESC);
CREATE INDEX idx_link_title ON link(title);

-- 미분류 폴더 기본 생성 (v1 onCreate 내부)
INSERT INTO folder (name, is_classified, created_at, updated_at)
  VALUES ('미분류', 0, ..., ...);
```

**v2 마이그레이션 시 추가 필요:**
```sql
ALTER TABLE folder ADD COLUMN parent_id INTEGER
  REFERENCES folder(id) ON DELETE CASCADE;
CREATE INDEX idx_folder_parent_id ON folder(parent_id);
```
기존 행들의 `parent_id`는 모두 NULL(최상위)로 남음. 미분류 폴더도 NULL.

### 10.4 P2 — 현재 Supabase 원격 스키마 (3개 migration 적용 상태)

**`profiles`** — `001_create_profiles.sql`
```
id UUID PK = auth.users.id
email TEXT
plan TEXT NOT NULL DEFAULT 'free' CHECK IN ('free','pro')
plan_expires_at TIMESTAMPTZ
created_at, updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
```
- `on_auth_user_created` 트리거로 신규 유저 가입 시 자동 row 생성
- RLS: SELECT/UPDATE만 (INSERT는 트리거, DELETE는 CASCADE)

**`folders`** — `002_create_folders.sql`
```
id UUID PK DEFAULT gen_random_uuid()
user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE
client_id INTEGER  (nullable!)
parent_id UUID REFERENCES folders(id) ON DELETE CASCADE
name TEXT NOT NULL
thumbnail TEXT
is_classified BOOLEAN NOT NULL DEFAULT true
created_at, updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
deleted_at TIMESTAMPTZ
```
- RLS: SELECT/INSERT/UPDATE/DELETE 모두 `auth.uid() = user_id`

**`links`** — `003_create_links.sql`
```
id UUID PK DEFAULT gen_random_uuid()
user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE
folder_id UUID NOT NULL REFERENCES folders(id) ON DELETE CASCADE
client_id INTEGER  (nullable!)
url TEXT NOT NULL
title, image, describe, inflow_type TEXT
created_at, updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
deleted_at TIMESTAMPTZ
```
- RLS: SELECT/INSERT/UPDATE/DELETE 모두 `auth.uid() = user_id`

**P2에서 추가할 migration 004 (섹션 4.3 참조) 요약:**
- `client_id`를 NOT NULL로
- `(user_id, client_id)` 복합 유니크 추가 (folders, links 둘 다)
- `deleted_at` 컬럼 제거 (folders, links 둘 다)
- `CREATE UNIQUE INDEX ... ON folders (user_id) WHERE is_classified = false` (미분류 1개 제약)
- `parent_id`는 유지

### 10.5 현재 Auth/Cubit 파일 위치 요약

| 파일 | 내용 |
|---|---|
| `lib/provider/auth/auth_repository.dart` (90줄) | `signInWithGoogle`, `signInWithApple`, `signOut`, `getPlan` (plan_expires_at 체크 포함) |
| `lib/cubits/auth/auth_cubit.dart` | `AuthState { status, user, plan, errorMessage }`, `isPro getter`. P2에서 `planExpiresAt`, `refreshPlan()`, free↔pro 전환 감지 로직 추가 예정 |
| `lib/main.dart` | `Supabase.initialize(url, anonKey)` 호출 (line 19-22). `.env`의 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 사용 |
| `lib/ui/page/my_page/my_page.dart` | Google/Apple 로그인 버튼, Pro 배지 표시. P2에서 백업/복구 섹션 추가 예정 |

### 10.6 AI 자동 분류 관련 파일

**앱에는 아직 없음.** 크롬 확장 쪽 Edge Function(`classify-link`)은 배포 완료. 앱에 클라이언트 래퍼와 UI 추가는 P3 스코프(아직 태스크 없음).

---

## 11. 열린 질문 (재개 시 결정 필요)

**현재 상태: P0/P1/P2 범위에서는 모든 정책 인터뷰로 확정됨. 이 섹션은 비어있음.**

다음과 같은 경우 이 섹션에 추가:
- 구현 중 발견된 새 결정 포인트
- 외부 환경 변화(예: Supabase 정책 변경)에 따라 재논의 필요한 항목
- 테스트 중 드러나는 엣지 케이스에 대한 정책

### 11.1 차기 Phase (P3, P4)의 미정 사항

현재 이 로드맵의 스코프 밖이지만, P2 완료 후 착수 시 결정 필요:

**P3 — AI 자동 분류 (앱 쪽):**
- UI 진입점: 링크 저장 시 "AI 추천" 버튼 vs 미분류 일괄 분류 메뉴 — 둘 다 할지, 하나만 할지
- Pro 게이팅 강도: Free도 일일 N회 허용? vs Pro 완전 전용?
- Edge Function 응답 대기 중 UX: 로딩 스피너 vs 백그라운드 진행

**P4 — 결제 연동 (RevenueCat):**
- 앱 전용? 크롬 확장은 "앱에서 결제" 안내만? — PAYMENT_PLAN.md 기준으로는 이게 맞음
- 구독 상품 구성: Monthly + Annual 두 가지 vs Lifetime 추가
- 가격: `PAYMENT_PLAN.md` 초기 설계(₩990/월)를 유지할지 재검토

**Pro 게이팅 세부 정책 (전체 공통):**
- 깨진 링크 체크 — Free도 허용? Pro만? (현재는 모든 유저 사용 가능, 미결정)
- 동기화/백업/복구 외에 Pro 전용으로 둘 기능 목록
- Free 유저에게 Pro 유도 UI를 얼마나 노출할지 (MyPage 외에 다른 지점?)

---
