# LinkPool 동기화 모델 v2 — 단일 진실원천 재설계

> 작성일: 2026-04-23
> 결정자: 프로덕트 오너 (kangmin)
> 상태: **승인됨, 구현 대기**
> 관련 문서: `docs/PRO_ROADMAP.md`, `docs/HANDOFF.md`, `linkpool-chrome-extension/`

---

## 0. 요약 (TL;DR)

기존 양방향 머지 모델(`mergeWithRemote` / `computeMerge` + 확장의 `incrementalSync`)은 **삭제 전파 구조적 결함**을 가지고 있어 폐기한다. 대신 다음 3원칙의 **단일 진실원천(Single Source of Truth) 모델**로 재설계한다.

1. **Free 상태**: 로컬 SQLite / `chrome.storage` 가 진실. 원격 서버 사용 안 함.
2. **Pro 상태**: 서버(Supabase)가 **유일한** 진실. 로컬은 서버의 읽기 캐시 + 미러. 모든 쓰기는 **온라인에서 원격 먼저**.
3. **전환점**: Free↔Pro 경계에서 단 한 번 **full replace** 로 데이터가 이동한다.

머지/유니온/툼스톤/`deleted_at` 전부 불필요. 삭제·리네임 전파 문제는 구조적으로 사라진다.

---

## 1. 배경 — 왜 재설계가 필요한가

### 1.1 현재(v1) 모델의 핵심 결함

#### A. 앱 `computeMerge` 는 union 머지
`lib/provider/sync/merge_compute.dart` L61~85 / L143~176:

```dart
} else if (local != null) {
  foldersLocalOnly++;
  mergedFolders.add(local.copyWith(...));   // 로컬 전용 → 결과에 포함
} else if (remote != null) {
  foldersRemoteOnly++;
  mergedFolders.add(_folderFromRemote(...)); // 원격 전용 → 결과에 포함
}
```

"한쪽에만 있는 항목" 을 **삭제된 것으로 구분할 수 없다.** 결과는 항상 **합집합**이라, 로컬에서 지운 폴더·링크가 원격에 남아 있으면 그대로 살아나 양쪽에 재삽입된다.

#### B. 앱 `backupToRemote` 는 로컬로 원격 full replace
`sync_repository.dart` L224~308: 원격 전체 DELETE → 로컬 전체 INSERT. `mergeWithRemote` 내부에서도 재사용되므로, union 머지 결과가 곧바로 원격을 덮어쓴다. → **로컬에만 있던 좀비가 서버로 승격**.

#### C. 확장 `incrementalSync` 는 삭제 push 없음
`linkpool-chrome-extension/src/supabase/sync.ts`:
- `pullFromServer` L174 : `.gt('updated_at', lastSync)` — 서버에서 hard delete 된 행은 쿼리에 잡히지 않음 → 확장 로컬에 영구 잔존.
- `reconcileIdMaps` L332~334 : 서버에 없는 uuid 를 `folderMap` 에서 제거 → 다음 `pushToServer` 에서 "새 폴더" 로 간주되어 **재삽입**.
- `pushToServer` 자체에 delete 로직 부재.

#### D. path_key 기반 머지 키의 부수 피해
`merge_compute.dart` L323~373 : path_key = 이름 + 부모 경로. 한쪽에서 리네임만 해도 양쪽 키가 달라져 **"한 폴더의 rename" 이 "로컬 전용 + 원격 전용" 두 건의 서로 다른 폴더**로 해석된다.

### 1.2 결론

어느 쪽에서 지웠는지 / 이름을 바꿨는지 / 새로 생성했는지를 구분하려면 최소한 **tombstone** 이나 **`deleted_at` soft delete** 가 필요하다. Migration 004 에서 이미 `deleted_at` 을 제거했으므로 되돌리는 비용이 크고, tombstone 도입도 세 상태(live / local-deleted / remote-deleted) 관리로 복잡도가 올라간다.

따라서 **머지 자체를 없앤다.** 진실원천을 한쪽에만 두는 것이 훨씬 단순하고 안정적이다.

---

## 2. 새 모델 — 상태 머신

```
                 ┌───────────────────────────────────────────┐
                 │                                           │
                 │           Free ───► Pro (전환 업로드)     │
                 │           ▲             │                 │
                 │           │             ▼                 │
                 │      (Free 복귀)    [Pro 활성]            │
                 │           │             │                 │
                 │           │             ▼                 │
                 │      (download +   ◄── Free              │
                 │       Grace 7일)                          │
                 │                                           │
                 └───────────────────────────────────────────┘
```

### 2.1 전환 (Free → Pro) — 로컬 우선 업로드

**트리거**: `AuthCubit` 이 `free → pro` 에지 감지 (결제 완료, 복구 구매, webhook 반영 등).

**동작**:
1. 로컬 스냅샷 확보 (`folders`, `links` 전체).
2. 원격 full replace — 기존 `backupToRemote()` 재사용 가능. 로직은:
   - `DELETE FROM links WHERE user_id = $1`
   - `DELETE FROM folders WHERE user_id = $1`
   - `INSERT folders (parent_id = null 로 먼저) → UPDATE parent_id 2-pass → INSERT links`
3. `lp_last_backup_at` 갱신.
4. Pro CRUD 훅 활성화 (다음 섹션).

**결정 #1 (2026-04-23)**: **원격에 기존 데이터가 있어도 무시하고 덮어쓴다.** 로컬이 우선. 경고 다이얼로그도 없음. 이 기기에서 Pro 전환을 일으킨 사용자 의도가 "이 기기의 상태를 클라우드에 올리겠다" 라고 단순하게 해석된다.

> 부수효과: 동일 계정으로 **다른 기기가 먼저 Pro 전환한 뒤 이 기기가 나중에 Pro 전환** 하면 앞 기기가 올린 내용이 날아간다. 현 시점 제품 규모(1인 계정, 기기 2대 이내)에서 허용 가능한 트레이드오프.

### 2.2 Pro 활성 기간 — 서버 = 진실, 로컬 = 미러

#### 쓰기 (CRUD)
모든 mutation 은 **원격 먼저 → 성공 후 로컬 반영**.

- 생성: `supabase.insert(...).select().single()` → 반환된 row 를 로컬에 insert. 실패 시 로컬에도 쓰지 않고 에러 토스트.
- 수정: `supabase.update(...)` → 성공 후 로컬 update.
- 삭제: `supabase.delete().match(...)` → 성공 후 로컬 delete.

기존 `lib/provider/sync/pro_remote_hooks.dart` 의 fire-and-forget 패턴은 **제거**한다. 실패를 삼키면 로컬/원격 불일치가 다시 생긴다.

#### 읽기 (Pull)
백그라운드 주기 pull + 명시 트리거 pull 조합:

| 시점 | 동작 |
|---|---|
| 앱 콜드 스타트 (Pro 감지 후) | full pull |
| `didChangeAppLifecycleState(resumed)` | full pull |
| MyPage / 폴더 리스트 진입 | full pull (debounce 5s) |
| 확장 사이드패널 오픈 | full pull |
| 확장 팝업 오픈 | full pull (debounce) |

**pull 알고리즘** (full replace, v1 의 `restoreFromRemote` 재사용):
```
1. SELECT * FROM folders WHERE user_id = $uid
2. SELECT * FROM links   WHERE user_id = $uid
3. DB transaction:
     TRUNCATE local folders, local links
     INSERT 원격 folders (parent_id 2-pass)
     INSERT 원격 links
     sqlite_sequence 보정
```

Pull 중 발생한 로컬 `createdAt`/`updatedAt` 보존은 서버 값 그대로 쓴다 (서버가 진실이므로).

#### 오프라인
**결정 #2 (2026-04-23)**: **오프라인 쓰기 미지원.** 온라인이 전제. 네트워크 연결 실패 시:

- 쓰기 UI: 즉시 토스트 "인터넷 연결이 필요해요" + 작업 롤백 (로컬도 안 바뀜).
- 읽기 UI: 마지막 pull 결과(로컬 미러)를 그대로 보여주되, 상단에 "오프라인 — 최근 동기화 MM/DD HH:mm" 배너 노출.
- pull 실패 시: 사용자에게 배너만, 자동 재시도 없음 (다음 lifecycle 이벤트에 재시도).

구현 포인트:
- `connectivity_plus` 로 네트워크 상태 체크 (앱). 확장은 `navigator.onLine` + 실패 감지.
- 쓰기 경로 통합 래퍼 `proMutate(() async {...})` 를 만들어 모든 CRUD 가 여길 거쳐가게 한다. 내부에서 네트워크·인증 체크·원격 호출·로컬 반영·에러 표시.

### 2.3 전환 (Pro → Free) — 다운로드 + Grace period

**트리거**:
- `plan_expires_at` 도래 (앱/확장 모두가 만료 시각에 맞춰 `refreshPlan`).
- 구독 취소 + 기간 종료 webhook.
- 결제 환불/실패.

**동작**:
1. **즉시** (Pro → Free 감지 순간):
   - 원격 전체를 로컬로 `restoreFromRemote()` — 로컬 full replace.
   - Pro CRUD 훅 비활성화. 이후 로컬 전용 모드.
   - 로컬 `lp_grace_until` = `now + 7 days` 기록.
2. **Grace period (7일) 내**:
   - 원격 데이터 **보존**. 삭제하지 않는다.
   - 이 기간 안에 다시 Pro 재구독하면:
     - 원격 데이터는 stale 상태지만 어차피 §2.1 에 따라 **로컬이 원격을 덮어씀** → Grace period 데이터는 버려진다. 문제 없음.
     - `lp_grace_until` 지워짐.
3. **Grace period 만료 후**:
   - Edge Function (또는 Supabase cron) 이 `auth.users` 에서 `plan_expires_at + 7d < now()` 인 유저의 `folders`/`links` 를 purge.
   - 이 청소는 서버 쪽에서 일괄 처리. 앱/확장은 아무것도 안 함.

**결정 #3 (2026-04-23)**: **Grace period = 7일.** 사용자가 실수로 구독을 끊었거나 결제 실패 사태에 복구 여지를 남긴다. 클라이언트 사이드 purge 는 하지 않는다.

---

## 3. 앱 (`ac_project_app`) 구현 범위

### 3.1 신규

| 위치 | 내용 |
|---|---|
| `lib/provider/sync/pro_mutate.dart` (신규) | 쓰기 통합 래퍼. 네트워크 체크 + 원격 호출 + 로컬 반영 + 에러 토스트. |
| `lib/cubits/sync/sync_state_cubit.dart` (신규 또는 기존 확장) | 온라인/오프라인, 마지막 pull 시각, pull-in-progress 상태 |
| `lib/util/connectivity.dart` (신규) | `connectivity_plus` wrapper (테스트 가능하게) |
| `supabase/migrations/005_grace_purge_cron.sql` (신규) | Grace period 만료 cron (pg_cron 또는 Edge Function 스케줄) |

### 3.2 수정

| 위치 | 내용 |
|---|---|
| `lib/provider/sync/sync_repository.dart` | `mergeWithRemote()`, `_applyMergeToLocal()` **삭제**. `backupToRemote()` 는 "Free → Pro 업로드" 전용으로 유지 + 주석 정리. `restoreFromRemote()` 를 "주기 pull" 겸용으로 확장. 단건 `upsertFolderRemote` / `upsertLinkRemote` / `deleteFolderRemote` / `deleteLinkRemote` 는 유지하되 `remoteWrite` 의 dirty flag 로직을 **제거**하고 호출부가 예외를 직접 처리하게 한다. |
| `lib/cubits/auth/auth_cubit.dart` | free→pro 에지: upload. pro→free 에지: download + grace flag. |
| `lib/provider/sync/pro_remote_hooks.dart` | fire-and-forget 제거 → `proMutate` 경유로 변경. 실패 시 호출부로 예외 전파. |
| `lib/provider/local/local_folder_repository.dart` / `local_link_repository.dart` | Pro 상태면 쓰기 경로가 `proMutate` 거치도록 분기. |

### 3.3 삭제

| 위치 | 사유 |
|---|---|
| `lib/provider/sync/merge_compute.dart` | union merge 전부 폐기 |
| `lib/provider/sync/merge_types.dart` | 동 |
| `test/provider/sync/merge_compute_test.dart` 등 | 머지 테스트 전부 |
| `SharedPreferences` 키 `lp_remote_dirty`, `lp_remote_dirty_since` 사용처 | dirty flag 모델 폐기 |
| MyPage 노란 "동기화 밀림" 배너 (§2.1 of HANDOFF) | dirty 자체가 없음 |

### 3.4 테스트 전략

- 단위 테스트: `proMutate` 의 네트워크 실패 / 인증 실패 / 성공 경로.
- 통합 테스트 (Supabase 로컬 인스턴스): Free→Pro, Pro 중 CRUD, Pro→Free 전환.
- 수동 실기기: 두 기기 동시 Pro 상태에서 기기 A 폴더 삭제 → 기기 B 에 10초 이내 반영 (lifecycle resumed 유발).

---

## 4. 확장 (`linkpool-chrome-extension`) 구현 범위

### 4.1 신규

| 위치 | 내용 |
|---|---|
| `src/supabase/pro-hooks.ts` (신규) | 앱의 `pro_remote_hooks` 와 동등. `createFolderRemote`, `updateFolderRemote`, `deleteFolderRemote`, `createLinkRemote`, `updateLinkRemote`, `deleteLinkRemote`. |
| `src/supabase/pro-mutate.ts` (신규) | `proMutate(fn)` — navigator.onLine 체크 + Supabase 호출 + 로컬 반영 + 에러 표시. |
| `src/supabase/full-pull.ts` (신규) | 원격 folders/links 전체 다운로드 → `chrome.storage.local` 트랜잭션 교체 (folders / links / NEXT_FOLDER_ID / NEXT_LINK_ID 전부 재세팅). |
| `src/supabase/transition.ts` (신규) | `onFreeToPro()` = 기존 `initialUpload` 강화. `onProToFree()` = download + grace 로컬 flag. |

### 4.2 수정

| 위치 | 내용 |
|---|---|
| `src/supabase/sync.ts` | **대부분 폐기**. `initialUpload` 는 `transition.ts` 로 이전 (로컬 우선, 원격에 기존 데이터 있어도 DELETE 후 INSERT). `incrementalSync`, `pullFromServer`, `pushToServer`, `reconcileIdMaps`, `findServer*` 전부 삭제. |
| `src/storage/storage.ts` | `createFolder` / `updateFolder` / `deleteFolder` / `createLink` / `updateLink` / `deleteLink` / `moveLink` 가 Pro 상태면 `proMutate` 경유하도록 분기. Free 면 기존 로컬 전용 경로. |
| `src/sidepanel/App.tsx` / `src/popup/App.tsx` | 오프라인 배너, "마지막 동기화 MM/DD HH:mm" 캡션, pull 트리거 훅. |
| `src/supabase/subscription.ts` | `getSubscriptionStatus()` 결과의 edge 감지. `refreshSubscription()` 에서 전환 트리거 호출. |

### 4.3 삭제

| 위치 | 사유 |
|---|---|
| `FOLDER_MAP_KEY`, `LINK_MAP_KEY` 사용처 | 로컬 정수 ID ↔ 서버 UUID 맵은 v2 에서도 필요하지만 **맵이 진실이 아니라 캐시** 이므로, full-pull 마다 재생성한다. sync.ts 의 `getFolderMap`/`setFolderMap` 유틸만 `full-pull.ts` 로 이관. |
| `LAST_SYNC_KEY` (`lp_sync_last_at`) | 증분 동기화 폐기로 불필요. 대신 `lp_last_pull_at` 정도로 UI 용 last-seen 기록. |

### 4.4 테스트 전략

- Vitest + jsdom: `proMutate` 분기 (online/offline/authed/unauthed).
- `full-pull` 트랜잭션: `chrome.storage.local` 을 fake 로 두고 교체 전/후 invariant (NEXT_*_ID ≥ max(id)+1) 검증.
- 수동: 앱에서 폴더 생성 → 확장 사이드패널 오픈 시 10초 이내 반영.

---

## 5. 서버 (Supabase) 변경

### 5.1 스키마
**변경 없음.** 기존 `folders` / `links` 테이블 그대로 (Migration 004 이후 상태 유지).

### 5.2 새 Migration 005 — Grace purge cron

두 가지 중 택일:

**옵션 A — Supabase pg_cron**
```sql
SELECT cron.schedule(
  'linkpool_grace_purge',
  '0 3 * * *',   -- 매일 03:00 UTC
  $$
    DELETE FROM links l
      USING auth.users u
     WHERE l.user_id = u.id
       AND u.raw_user_meta_data->>'plan_expires_at' IS NOT NULL
       AND (u.raw_user_meta_data->>'plan_expires_at')::timestamptz + interval '7 days' < now();

    DELETE FROM folders f
      USING auth.users u
     WHERE f.user_id = u.id
       AND u.raw_user_meta_data->>'plan_expires_at' IS NOT NULL
       AND (u.raw_user_meta_data->>'plan_expires_at')::timestamptz + interval '7 days' < now();
  $$
);
```

**옵션 B — Edge Function + Supabase Scheduled Trigger**
`supabase/functions/grace-purge/index.ts` 작성 → Supabase 대시보드에서 cron 스케줄.

결정 보류 — Supabase 플랜 차이 (pg_cron 은 Pro 플랜 필요). 현 프로젝트는 Free 플랜으로 시작했으므로 **옵션 B** 가 안전.

---

## 6. 데이터 흐름 다이어그램

### 6.1 Free → Pro 전환
```
[App Local SQLite]        [Supabase]
      │                        │
      │  snapshot               │
      ├────────────────────────►│  DELETE FROM folders WHERE user_id=$
      │                        │  DELETE FROM links   WHERE user_id=$
      │                        │
      │  INSERT folders         │
      ├────────────────────────►│
      │                        │
      │  UPDATE parent_id       │
      ├────────────────────────►│
      │                        │
      │  INSERT links           │
      ├────────────────────────►│
      │                        │
      │  ✓ set lp_last_backup_at
      │  ✓ activate Pro hooks
```

### 6.2 Pro 중 CRUD (create folder 예)
```
[UI] ──► [proMutate] ──► [Supabase INSERT] ──► [Local INSERT]
             │                  │
             │                  └─ 실패 ──► Toast "인터넷 필요"
             │                              (로컬 변화 없음)
             └─ offline ──► Toast "인터넷 필요" (원격 호출 생략)
```

### 6.3 Pro 중 Pull (주기)
```
[Lifecycle resumed] ──► [full-pull.ts]
                            │
                            ▼
                        SELECT folders
                        SELECT links
                            │
                            ▼
                        Local TX begin
                          TRUNCATE local
                          INSERT server rows
                          sqlite_sequence 보정
                        Local TX commit
                            │
                            ▼
                        lp_last_pull_at = now
```

### 6.4 Pro → Free 전환
```
[plan_expires_at 도래 감지]
        │
        ▼
[restoreFromRemote]  (원격 → 로컬 full replace, 동일 함수)
        │
        ▼
[Pro hooks 비활성화]
        │
        ▼
[lp_grace_until = now + 7d 기록]
        │
        ▼
(7일 후 서버 cron 이 원격 purge — 클라이언트 개입 없음)
```

---

## 7. 마이그레이션 계획

### 7.1 기존 Pro 유저 데이터 보존

현 시점(2026-04-23)의 Pro 유저:
- `linkpooltest2@gmail.com` (`355d0598-e5e0-4ece-bb14-1dd03ec8e344`) — 테스트 계정.

기존 유저에 미치는 영향 없음. v2 배포 후 최초 lifecycle 이벤트에 full pull 이 돌아 로컬이 원격과 동기화되는 것이 유일한 차이.

### 7.2 배포 순서

1. 앱 / 확장 v2 코드 동시 배포 (양쪽이 달라지면 앱이 오래된 버전일 때 v1 로직이 v2 서버 상태를 꼬이게 할 여지).
2. Migration 005 (grace cron) 는 배포 직후 수동 실행.
3. 확장 Chrome Web Store 는 심사 기간이 있으므로, 앱 v2 를 먼저 배포하고 확장은 기존 v1 유지 → 확장 심사 통과 후 스위치. 이 기간 동안 확장 쪽은 pull-only 모드 (쓰기는 앱에서만) 로 임시 운영.
   - 구현: 확장 v1.x 마지막 버전에 쓰기 비활성화 feature flag 를 넣어두면 이 공백을 버틸 수 있음. (별도 hotfix 필요)

### 7.3 데이터 손실 시나리오 사전 공지

앱 릴리스 노트에 다음 경고 포함:

> **⚠️ 동기화 정책이 변경됩니다 (v1.x.y)**
> Pro 구독자가 두 대 이상의 기기를 쓰는 경우, 이번 업데이트 후 **이 기기에서 처음 앱을 열 때** 클라우드 데이터가 현재 기기의 로컬 데이터로 덮어씌워집니다. 다른 기기에서만 추가된 폴더/링크가 있다면, 업데이트 **전에** 모든 기기를 동기화해 주세요.

---

## 8. 결정 이력

### 2026-04-23 — 모델 선택

| 질문 | 결정 | 근거 |
|---|---|---|
| Pro 전환 시 원격에 기존 데이터 있으면? | **무시 + 로컬로 덮어씀** | 사용자 의도 단순화. "이 기기의 상태를 올리는 것" 이라는 직관적 해석. |
| Pro 기간 중 오프라인 쓰기? | **미지원, 온라인 전제** | 오프라인 큐 도입 시 머지가 다시 필요해짐 → 재설계 목적 훼손. |
| Pro → Free 전환 시 원격 purge? | **Grace period 7일 보존 후 서버 cron 정리** | 결제 실수 복구 여지 + 구현 단순성. |

### 2026-04-23 — 폐기 결정

- `lib/provider/sync/merge_compute.dart` / `merge_types.dart` 삭제 (union merge 문제의 원인).
- 확장 `incrementalSync` 전 영역 삭제.
- `lp_remote_dirty` / `lp_remote_dirty_since` / 관련 UI 배너 전부 제거.

---

## 9. 구현 체크리스트

### 9.1 앱
- [ ] `lib/util/connectivity.dart` 신규
- [ ] `lib/provider/sync/pro_mutate.dart` 신규
- [ ] `SyncRepository.mergeWithRemote` / `_applyMergeToLocal` 삭제
- [ ] `backupToRemote` 주석 정리 (Free→Pro 업로드 전용 명시)
- [ ] `restoreFromRemote` 를 "주기 pull" 겸용으로 확장 (호출처 분기)
- [ ] `upsert*Remote` / `delete*Remote` 의 `remoteWrite` dirty flag 제거, 예외 상향
- [ ] `pro_remote_hooks.dart` 가 `proMutate` 경유
- [ ] `AuthCubit` 에 free↔pro 에지 동작 구현 (업로드 / 다운로드 + grace flag)
- [ ] `MyPage` 의 동기화 밀림 배너 제거
- [ ] `merge_compute.dart` / `merge_types.dart` + 테스트 삭제
- [ ] 단위 테스트: `proMutate`
- [ ] 통합 테스트: 전환 시나리오
- [ ] 실기기: Galaxy A52s + iPhone 동시 Pro 시나리오

### 9.2 확장
- [ ] `src/supabase/pro-mutate.ts` 신규
- [ ] `src/supabase/pro-hooks.ts` 신규
- [ ] `src/supabase/full-pull.ts` 신규
- [ ] `src/supabase/transition.ts` 신규 (`onFreeToPro`, `onProToFree`)
- [ ] `src/supabase/sync.ts` 에서 `incrementalSync` / `pullFromServer` / `pushToServer` / `reconcileIdMaps` / `findServer*` 삭제
- [ ] `src/supabase/subscription.ts` 에서 plan 에지 감지 후 transition 호출
- [ ] `src/storage/storage.ts` 의 쓰기 메서드가 Pro 면 `proMutate` 경유하도록 분기
- [ ] 사이드패널 / 팝업 상단에 "오프라인" 배너 + "마지막 동기화 MM/DD HH:mm" 캡션
- [ ] `FOLDER_MAP_KEY` / `LINK_MAP_KEY` 를 full-pull 의 부산물로 전환
- [ ] Vitest: `proMutate`, `full-pull` transaction invariant
- [ ] Chrome Web Store 업데이트 전까지 확장 v1 에 쓰기 비활성화 flag 핫픽스

### 9.3 서버
- [ ] `supabase/migrations/005_grace_purge_cron.sql` 또는 Edge Function `grace-purge`
- [ ] 프로덕션 Supabase 대시보드에서 cron 스케줄 등록
- [ ] 릴리스 노트에 마이그레이션 경고 추가

---

## 10. 오픈 이슈 (후속)

- **확장 v1 공백 기간의 쓰기 비활성화 flag** — Chrome Web Store 심사가 5~7일 걸리면 앱 v2 배포 후 확장이 구버전으로 남아 있는 동안 확장에서 쓰기를 일으키면 서버와 꼬인다. 확장 v1 마지막 릴리스에 원격 flag(`chrome.storage.local` 또는 Supabase 공개 테이블) 읽고 쓰기 UI 를 비활성화하는 코드를 미리 심어두는 hotfix 가 필요. 상세 설계는 구현 단계에서.
- **Pro 기간 중 두 기기 동시 편집 race** — last-write-wins 서버 UPDATE 가 수렴 보장. 다만 같은 초(second) 에 두 기기가 동시 편집 시 더 나중에 Supabase 에 도달한 쓰기가 이긴다. 정상 동작.
- **전환 직후 cold start UX** — Free → Pro 직후 앱 재시작하면 전환 업로드가 이미 끝났으므로 pull 만 일어남. 문제 없음. 단 업로드 진행 중 앱 강제 종료 시에 중단 → 부분 업로드 상태. `backupToRemote` 의 트랜잭션 경계를 고민 (현재는 여러 번의 Supabase 호출이라 중간 실패 가능). Edge Function 으로 업로드를 서버 단 트랜잭션으로 묶는 것도 옵션.

---

## 11. 참고 링크

- 현 v1 로직:
  - 앱: `lib/provider/sync/sync_repository.dart`, `merge_compute.dart`
  - 확장: `linkpool-chrome-extension/src/supabase/sync.ts`
- 결정 배경:
  - 세션 로그 2026-04-23 (삭제 전파 결함 발견)
  - `docs/HANDOFF.md` §2 정책 이력
