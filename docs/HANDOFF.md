# LinkPool 앱 — 세션 Handoff

> 작성일: 2026-04-23 (Sync v2 머지 + Supabase 배포 완료 시점)
> 문서 성격: 세션 초기화 후 새 세션에서 이 파일만 읽고 바로 이어가기 위한 남은-작업 리스트
> 관련 문서:
> - `docs/SYNC_MODEL_V2.md` — Sync v2 설계
> - `docs/PRO_ROADMAP.md` — P0/P1/P2 전체 로드맵
> - `supabase/README.md` — Supabase 자산 배포 기록

---

## Quick Resume

- **브랜치**: `develop` (= `origin/develop`). 마지막 커밋 `83f060f1 Merge branch 'feat/sync-v2' into develop`
- **빌드/테스트**: `fvm flutter analyze lib/` clean, `fvm flutter test` **221 passed, 0 failed**
- **Supabase 운영 자산 전부 배포 완료**:
  - `linkpool_grace_purge()` pg function
  - Edge Function `grace-purge`
  - pg_cron job `linkpool_grace_purge_daily` (매일 03:00 UTC)

---

## 남은 작업

### 1. Phase B — Chrome 확장 v2 전환 (별도 저장소)

저장소: `/Users/kangmin/dev/linkpool-chrome-extension`. 참조: `docs/SYNC_MODEL_V2.md` §4.

- [ ] `src/supabase/pro-mutate.ts` — `proMutate(fn)` 래퍼 (navigator.onLine + 예외 분리)
- [ ] `src/supabase/pro-hooks.ts` — createFolder/updateFolder/deleteFolder/createLink/updateLink/deleteLink
- [ ] `src/supabase/full-pull.ts` — 원격 folders/links 전체 다운로드 → `chrome.storage.local` 트랜잭션 교체
- [ ] `src/supabase/transition.ts` — `onFreeToPro()` (initial upload), `onProToFree()` (download + grace)
- [ ] `src/supabase/sync.ts` 대거 폐기: `incrementalSync`, `pullFromServer`, `pushToServer`, `reconcileIdMaps`, `findServer*`
- [ ] `src/storage/storage.ts` CRUD 가 Pro 면 `proMutate` 경유
- [ ] `src/sidepanel/App.tsx` / `src/popup/App.tsx` — 오프라인 배너, "마지막 동기화" 캡션, pull 훅
- [ ] `src/supabase/subscription.ts` plan edge 감지 → transition 호출
- [ ] `FOLDER_MAP_KEY` / `LINK_MAP_KEY` 를 full-pull 부산물로 전환
- [ ] Vitest: `proMutate` 분기, `full-pull` 트랜잭션 invariant
- [ ] Chrome Web Store 심사 공백용 v1 쓰기 비활성화 flag 핫픽스 (SYNC_MODEL_V2 §7.2, §10)

### 2. Phase 2 — Chrome 확장 중첩 폴더 생성 UI

- [ ] 트리 UI 에 "하위 폴더 추가" 진입점 추가 (`storage.createFolder(name, parentId, bookmarkId)` 는 이미 parentId 수용)

### 3. 실기기 회귀 검증 (Galaxy A52s `R5CRB2A38HM` / iPhone)

Sync v2 관련 UI/동작을 사람 눈으로 확인:
- [ ] Free → Pro 전환 시 **ProBackupDialog** (indeterminate spinner + "폴더/링크 업로드 중")
- [ ] 오프라인 상태에서 앱 진입 → **OfflineDialog** ("인터넷 연결이 필요해요") 1회 노출
- [ ] Pro CRUD 도중 네트워크 끊김 → OfflineDialog
- [ ] lifecycle resumed / 탭 진입 시 원격 pull 로 로컬 폴더/링크 갱신 (다른 기기 변경이 반영됨)
- [ ] 5s debounce — 연속 탭 전환해도 원격 호출 과다 발생 안 함
- [ ] Pro → Free 전환 → 로컬 데이터 보존 (서버는 Grace 7일 후 cron 이 정리)
- [ ] 재구독 시 `lp_grace_until` 제거 + 로컬이 원격 덮어씀

기존 중첩 폴더 시각 검증 잔여:
- [ ] 깨진 링크 체크 다이얼로그 (공통 톤 / 중지 / 1건 단위 진행률 / empty / cancelled) — 링크 있는 상태에서만
- [ ] PickFolderSheet 최근 사용 (이동 1회 후 노출)
- [ ] PickFolderSheet 드릴다운 경로 바 (`루트 > 일 > 개발`)
- [ ] 신규 기기 자동 복원 시뮬레이션

### 4. 실 Apple ID 수동 E2E

- [ ] 앱에서 Apple로 가입 (iOS 테스터) → 크롬 확장에서 Apple 로그인 → Supabase `auth.users` 같은 UUID 재사용
- [ ] 로그아웃 → 재로그인 사이클 양쪽

### 5. 결제 (RevenueCat) 연동

`docs/PRO_ROADMAP.md` §5 상세. 요약:
- [ ] C-1 앱 RevenueCat 인앱결제 코드 (`ac_project_app`)
- [ ] C-2 RevenueCat 웹훅 Edge Function (`linkpool-chrome-extension/supabase/functions/`)
- [ ] C-3 크롬 확장 "앱에서 결제" 안내 UI (`linkpool-chrome-extension`)
- [ ] S-7 외부 설정 9건 — `linkpool-chrome-extension/docs/PAYMENT_PLAN.md` A-1~A-9
- [ ] 구매 성공 콜백에서 `AuthCubit.refreshPlan()` 명시 호출
- [ ] `plan_expires_at` 만료 타이머 예약 (현재는 앱 시작/resumed 시에만 체크)

### 6. Dependabot 취약점 잔여 (high 2건)

`bundle-audit` 로컬 스캔은 깨끗함. GitHub Actions 또는 ruby-advisory-db 미반영 CVE 가능성.
- [ ] 알림에 뜬 패키지명을 확인한 뒤 대응

### 7. 후속 리팩터링 (선택)

- [ ] `folder_name_cubit.dart` 완전 폐기 — rename 다이얼로그를 `showCreateFolderSheet` 와 유사한 dumb 시트 패턴으로 리팩터
- [ ] `pick_folder_sheet` 실시간 구조 반영 (현재 스냅샷 기반)
- [ ] CRUD 원격-선행 엄격화 — 현재는 "로컬-선행 → 원격 await, 오프라인 예외 삼킴 + 다음 pull 이 정정" 타협 중. v2 §2.2 원안(원격 먼저 → 성공해야 로컬)으로 전환하려면 create 롤백 + UI 낙관적 업데이트 취소 필요

---

## 현재 원격/환경 스냅샷

### Supabase
- URL: `https://gystdpdelnfblgyeckth.supabase.co`
- Project ref: `gystdpdelnfblgyeckth`
- Auth providers: Google, Apple 활성
- Google Authorized Client IDs: Web application 타입 포함 (`...cm6c89...`)
- Migration 004 (이전 세션) + Migration 005 (이번 세션) 적용 완료
- pg_cron `linkpool_grace_purge_daily` (jobid=1) 매일 03:00 UTC 실행
- 테스트 유저: `linkpooltest2@gmail.com` (`id = 355d0598-e5e0-4ece-bb14-1dd03ec8e344`), plan=`pro`

### 디바이스
- Galaxy A52s (`R5CRB2A38HM`, Android 14) — debug 빌드 검증됨
- iPhone (boring-km) — wifi 연결
- Debug SHA-1: `AE:8F:D9:E5:DF:EB:B5:A0:4A:7D:DC:81:08:35:E6:C4:08:1E:36:64`
- Release SHA-1: `50:51:26:42:7A:94:28:BE:A0:CF:F9:14:3D:6B:97:87:BA:2A:F2:99`

### git
- 브랜치: `develop` = `origin/develop`
- 마지막 머지: `83f060f1 Merge branch 'feat/sync-v2' into develop`

### Ruby/Bundler
- 로컬 bundler 2.5.3 (rbenv shim)
- Gemfile.lock `BUNDLED WITH` 은 **2.6.2** 유지 — gem 업데이트 후 다운그레이드 방지를 위해 수동 복구

---

## 자주 쓰는 명령어

```bash
# 로컬 개발
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze lib/
fvm flutter test

# 실기기
fvm flutter devices
fvm flutter run -d R5CRB2A38HM

# Supabase 운영 SQL (DB 직접 접속)
/opt/homebrew/opt/libpq/bin/psql "$LINKPOOL_SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f <file>

# Supabase Edge Function 재배포
supabase functions deploy grace-purge --project-ref gystdpdelnfblgyeckth

# Dependabot 로컬 스캔
export PATH="/Users/kangmin/.gem/ruby/3.3.0/bin:$PATH"
(cd android && bundle-audit check)
(cd ios && bundle-audit check)
```

---

## Sync v2 주요 파일 (2026-04-23)

- `lib/provider/sync/sync_repository.dart` — `upsert*Remote` / `delete*Remote` / `backupToRemote({onPhase})` / `restoreFromRemote` / `pullFromRemote({force})` / `offlineNotifier`
- `lib/provider/sync/pro_mutate.dart` — `proMutate<T>({remote, local})` + `ProMutateOfflineException`
- `lib/provider/sync/pro_remote_hooks.dart` — Pro CRUD 원격 전파, 오프라인 예외 감지 시 `markOffline`
- `lib/cubits/auth/auth_cubit.dart` — free↔pro 에지, Grace period, `_runInitialBackup` 오케스트레이션
- `lib/ui/widget/dialog/pro_backup_dialog.dart` — Free→Pro 업로드 로딩 Dialog
- `lib/ui/widget/dialog/offline_dialog.dart` — 오프라인 안내 Dialog
- `lib/ui/view/home_view.dart` — lifecycle/탭 pull 훅 + offline listener + backup Dialog 노출 관리
- `supabase/migrations/005_grace_purge_function.sql`, `supabase/functions/grace-purge/index.ts`, `supabase/README.md`
