# LinkPool 앱 — 세션 Handoff

> 작성일: 2026-04-23 (v4 — Sync v2 Phase A/A' + 오프라인 팝업 + Grace purge pg function 머지 후)
> 문서 성격: **세션이 초기화돼도 새 세션에서 이 파일만 읽고 바로 이어갈 수 있도록 작성된 handoff**
> 관련 문서:
> - `docs/SYNC_MODEL_V2.md` — **🆕 동기화 모델 재설계 (2026-04-23 결정, 구현 대기)** — 기존 union merge 폐기, Pro=서버가 진실 / Free=로컬이 진실 / 전환점에서만 full replace
> - `docs/PRO_ROADMAP.md` — P0 / P1 / P2 전체 로드맵과 설계 결정 이력
> - `docs/HANDOFF_nested_folder_create.md` — 중첩 폴더 생성 Phase 1 상세 (이미 머지됨, 히스토리 참조용)
> - `docs/superpowers/specs/2026-04-23-nested-folder-create-design.md` — 중첩 폴더 설계 스펙
> - `docs/superpowers/plans/2026-04-23-nested-folder-create-plan.md` — 중첩 폴더 구현 계획
> - `linkpool-chrome-extension/docs/REMAINING_TASKS.md` — 크롬 확장 쪽 남은 작업
> - `linkpool-chrome-extension/docs/APPLE_LOGIN.md` — 크롬 확장 Apple 로그인 (코드 완료, 실 Apple ID E2E만 남음)
> - `linkpool-chrome-extension/docs/PAYMENT_PLAN.md` — 결제 외부 설정 A-1~A-9

---

## Quick Resume (재개 시 이것부터)

1. **현재 코드 상태**: `feat/sync-v2` 브랜치에 Sync v2 Phase A + A' + 오프라인 팝업 + Phase C(Migration 005) 커밋. develop 머지 대기 중.
   - Phase A: union merge 폐기 + proMutate + dirty flag 전면 제거 + Grace period + Pro 업로드 로딩 Dialog
   - Phase A': 주기 pull (lifecycle resumed / 콜드 스타트 / 탭 진입) + 5s debounce
   - 오프라인 팝업: SyncRepository.offlineNotifier + OfflineDialog (Pro 전용, HomeView 구독)
   - Phase C: `supabase/migrations/005_grace_purge_function.sql` + `supabase/functions/grace-purge/index.ts` (수동 배포 대기)
2. **Phase B 미착수**: Chrome 확장 v2 (별도 저장소 `linkpool-chrome-extension`). `docs/SYNC_MODEL_V2.md` §4 참조.
3. **다음 해야 할 일 우선순위**:
   1. `feat/sync-v2` → `develop` 머지
   2. Supabase 대시보드에서 Migration 005 + Edge Function 배포 (`supabase/README.md` 가이드 참조)
   3. **Phase B — Chrome 확장 v2 전환** (`linkpool-chrome-extension` 저장소)
   4. 실기기 시각 검증 잔여 (섹션 1.1) — Pro 업로드 Dialog, 오프라인 팝업, 주기 pull 등
   5. 실 Apple ID 수동 E2E (섹션 1.3)
   6. 결제(RevenueCat) 연동 (섹션 5)
   7. 남은 Dependabot 취약점 2건 (high) (섹션 1.4)
4. **빌드/테스트 현황**: `fvm flutter analyze lib/` clean (info만), `fvm flutter test` **221 passed, 0 failed**.
4. **마지막 실동작 검증됨 (2026-04-23, Galaxy A52s `R5CRB2A38HM`)**:
   - 중첩 폴더 생성 Task 9 — Step 1/2/4 통과
     - `A.parent_id = null` ✅
     - `B.parent_id = A.id` ⭐ 2-pass 패턴 검증
     - 고아 부모 시나리오 → 자기치유 동작 확인 (k가 dirty 보정 백업으로 올바른 parent_id로 업로드)
5. **미검증 (실기기 시각 확인 남음)**:
   - 깨진 링크 체크 다이얼로그 (공통 톤 / 중지 / 1건 단위 진행률 / empty / cancelled)
   - 드릴다운 페이지 / 트리 모달 / PickFolderSheet 시각 톤
   - 신규 기기 자동 복원 (조용한 복원)

---

## 1. 🔧 남은 작업 — 구체적

### 1.1 🖥️ 실기기 시각 검증 — **우선 처리**

에뮬레이터에서 `adb` 자동화로는 한계가 있어 사람 눈으로 확인해야 하는 항목들:

- [ ] 루트 폴더 페이지 — 트리 아이콘 + 검색창 + 미분류 + 루트 폴더들
- [ ] 트리 아이콘 탭 → **전체 폴더 트리 모달** 노출, 펼침/접힘 (▶/▼)
- [ ] 루트 폴더 탭 → **드릴다운 페이지** 진입: 상단 브레드크럼 + `하위 폴더` 섹션 + `이 폴더의 링크` 섹션
- [ ] 드릴다운에서 하위 폴더 탭 → 재귀 드릴다운 (브레드크럼 2뎁스 이상)
- [ ] 브레드크럼 중간 노드 탭 → 해당 폴더로 점프
- [ ] 폴더 옵션(…) → **폴더 이동** → `PickFolderSheet` 열림
- [ ] `PickFolderSheet` 검색 — 폴더명 입력 시 경로(`상위 > 하위`) 함께 표시
- [ ] `PickFolderSheet` 최근 사용 — 한 번이라도 폴더 이동하면 상단에 최대 5개 표시
- [ ] `PickFolderSheet` 드릴다운 — `>` 버튼으로 하위 진입, 상단 경로 바에 `루트 > 일 > 개발` 구조 표시
- [ ] 폴더 옵션 → 폴더 이동 → 자기/후손 폴더는 **disable(회색)** 상태
- [ ] 미분류 폴더에 옵션(…) 버튼이 노출되지 않음
- [ ] MyPage — Pro 유저에서 계정 영역 아래 `Pro · 마지막 백업 MM/DD HH:mm` 캡션 노출
- [ ] 신규 기기 로그인 시뮬레이션 — 앱 로그아웃 + 로컬 DB 초기화 + 재로그인 → **팝업 없이** 자동 복원 (`_maybeAutoRestore`)
- [ ] **깨진 링크 체크 다이얼로그** — MyPage → `깨진 링크 체크`:
  - 공통 톤 (흰 Dialog 카드, 16.w radius, 우상단 close, primary600 CTA)
  - 1/N 부터 1개 단위로 올라가는 진행률 바
  - 검사 중 **"중지"** 버튼 → 탭 시 즉시 `cancelled` 상태로 전환 (`N/M개까지 확인했어요`)
  - 링크 0건일 때 "검사할 링크가 없어요" 안내
  - HEAD 차단하는 사이트(네이버/유튜브 등)가 GET fallback으로 정상 판정되는지

### 1.2 🆕 Phase 2 — Chrome 확장 중첩 폴더 생성 UI

저장소: `/Users/kangmin/dev/linkpool-chrome-extension`

- [ ] 트리 UI에 "하위 폴더 추가" 진입점 추가
- [ ] `storage.createFolder(name, parentId, bookmarkId)`는 이미 parentId 수용 → UI만 작업
- [ ] 별도 스펙/플랜 작성 후 진행 (앱 Phase 1 머지로 백엔드 계약은 확정됨)

### 1.3 Apple 로그인 수동 E2E

- [ ] 앱에서 Apple로 가입한 유저 (iOS 테스터 계정) → 크롬 확장에서 Apple 로그인 → Supabase `auth.users` 같은 UUID 재사용 확인
- [ ] 로그아웃 → 재로그인 사이클 (앱 / 크롬 확장 양쪽)

### 1.4 Dependabot 취약점 잔여

이전 세션에 4건 해결. **원격 배너 기준 2건 (high) 남음.**
- 패키지명을 알려주시면 즉시 대응 가능. bundler-audit 로컬 스캔은 0건으로 깨끗하므로 ruby-advisory-db에 아직 반영되지 않은 신규 CVE이거나 GitHub Actions 쪽일 가능성.

### 1.5 후속 리팩터링 (선택)

- [ ] `folder_name_cubit.dart` 완전 폐기 — rename 다이얼로그도 `showCreateFolderSheet`와 유사한 dumb 시트 패턴으로 리팩터하면 `FolderNameCubit`/`ButtonStateCubit` 모두 폐기 가능
- [ ] `pick_folder_sheet` 실시간 구조 반영 — 현재 스냅샷 기반. 로드 중 원격 머지로 구조 바뀌면 반영 안 됨

---

## 2. 🎯 정책 / 동작 변경 이력 (중요 컨텍스트)

### 2.1 백업/복원 UX: **자동 우선 + 필요할 때만 UI 등장**

- MyPage의 상시 노출되던 백업&복원 카드 **제거**
- 계정 영역 아래 한 줄 캡션: `Pro · 마지막 백업 MM/DD HH:mm`
- 신규 기기 자동 복구 팝업 **제거** → 조건(Pro + 로컬 links=0 + 원격 백업 있음) 만족 시 **조용히** `restoreFromRemote()`
- 동기화 밀림 배너: `isDirty==true` 가 **30분 이상 지속**된 경우에만 MyPage 상단에 노란 배너 + `지금 백업` 버튼

관련 커밋: `3afaa098 feat: 백업/복원 UI 자동 우선 전환`

### 2.2 Google 로그인 — Web Client ID로 전환

- Android serverClientId를 Chrome Extension과 공유하는 **Web application 타입** Client ID 사용:
  `310694628669-cm6c89tss9g8vbp5dtd173gpe64bs0on.apps.googleusercontent.com`
- 이전 Android 타입 Client ID를 쓰면 Credential Manager가 `[28444] Developer console is not set up correctly` 를 뱉음.
- Supabase Auth → Providers → Google → Authorized Client IDs 에 이 Web Client ID 등록 완료.

관련 커밋: `03da1de9 fix: Android Google 로그인을 Web Client ID 기반으로 전환`

### 2.3 HomeView Provider 스코프

`AuthCubit` lifecycle 접근을 `Builder` 로 감싼 innerCtx 에서 ref 캡처. lifecycle 훅은 캡처된 ref 사용.
관련 커밋: `2fe83395 fix: AuthCubit provider 접근 불가 문제 해결 (HomeView self-scope)`

### 2.4 깨진 링크 체크 다이얼로그 — 공통 톤 + 중지 + 1건 단위 진행률

- **UI**: `AlertDialog` → 프로젝트 공통 `Dialog` 카드로 교체 (흰 배경, 16.w radius, 우상단 `Icons.close_rounded`, primary600 CTA, Pretendard)
- **Cubit**: 생성자에서 `autoStart` 로 즉시 검사 시작. `empty` / `cancelled` 상태 추가. `cancel()` 메서드로 즉시 `cancelled` emit + 내부 토큰 cancel.
- **Checker**:
  - `LinkCheckCancelToken` 으로 배치 단위 취소 지원
  - HEAD 405/403/501 → GET fallback (네이버/유튜브 등 HEAD 차단 사이트 false-positive 방지)
  - HEAD 예외 → GET 재시도
  - 잘못된 URL(스킴 없음, parse 실패)은 HTTP 요청 없이 즉시 실패
  - `onProgress` 가 URL 1개 완료마다 1씩 증가 (이전: 배치 10개 단위 점프). 원본 URL 순서는 보존.
- **CTA 분기**: `checking/initial` 일 땐 **"중지"**, 그 외엔 **"확인"**.

관련 커밋: `8853058f feat: 깨진 링크 체크 다이얼로그 개선`

### 2.5 Dependabot 취약점 대응 (4건 해결, 2건 잔여)

| gem | 이전 | 이후 | CVE |
|---|---|---|---|
| faraday | 1.10.4 | 1.10.5 | CVE-2026-25765 SSRF (GHSA-33mh-2634-fwr2, Medium) |
| json | 2.18.1 | 2.19.4 | CVE-2026-33210 format string injection |
| addressable | 2.8.8 | 2.9.0 | Dependabot alert (High) |

- **주의**: `bundle update` 시 `BUNDLED WITH` 가 로컬 bundler 버전(2.5.3)으로 다운그레이드되는 현상 있음 → 반드시 `2.6.2` 로 복구 후 커밋
- `bundle-audit check` 기준 android/ios 모두 "No vulnerabilities found"

관련 커밋: `ebb5c083`, `1ce01129`

### 2.6 🆕 중첩 폴더 생성 Phase 1 (2026-04-23 머지 완료)

머지 커밋: `247a687f Merge branch 'feat/nested-folder-create' into develop` (no-ff, 21 files, +4885/-409)

**핵심 변경**:
- 앱에 "특정 폴더 아래에 새 폴더 만들기" 진입점 **3개** 추가:
  1. MyLinkView "하위 폴더 (N)" 헤더 `+` (key `my_link_view_add_child_folder`)
  2. 우상단 `...` 옵션 시트 "하위 폴더 추가" (최상단)
  3. 내 폴더 탭 루트 "+" (key `my_folder_page_create_root_folder`)
- 공유/업로드 플로우는 **루트 고정** (`allowParentPick: false`)
- `showAddFolderDialog` 폐기 → **`showCreateFolderSheet`** 전면 교체
- **`SyncRepository.upsertFolderRemote` 2-pass 패턴 적용** ⭐ — 단건 업서트에서 `parent_id` 유실되던 숨은 버그 fix
- `isSiblingNameTaken` — 형제 범위 + 미분류 제외
- `CreateFolderResult` sealed + `FolderException` 타입 도입

**동작**:
- 중첩 깊이: **무제한**. 자기-후손 이동 금지만 유지
- 이름 중복 범위: **형제 범위만** 금지. 경로 다르면 동명 허용. 바이트-equal (대소문자/유니코드 정규화 안 함)
- 미분류 폴더에서는 "하위 폴더" 섹션 자체가 숨겨짐 → 중첩 생성 경로 봉쇄

**검증 결과 (Galaxy A52s, Pro 계정 `linkpooltest2@gmail.com`)**:
- Step 1: `A` 루트 생성 → `parent_id=null` ✅
- Step 2: `A` 안에 `B` 생성 → `B.parent_id = A.id` ⭐
- Step 4: Supabase에서 `A` 직접 삭제 후 앱에서 `k` 생성 → 자기치유 (dirty 보정 백업으로 `A` 부활 + `k`도 올바른 `parent_id`로 업로드) ✅
- (Step 3 오프라인 시나리오는 스킵)

**유지된 것**: `lib/cubits/folders/folder_name_cubit.dart`는 `show_rename_folder_dialog.dart`가 여전히 사용 중이라 **삭제 안 함** (후속 리팩터링 이슈, §1.5)

---

## 3. 🔑 현재 원격/환경 상태 스냅샷

### 3.1 Supabase
- 프로젝트 URL: `https://gystdpdelnfblgyeckth.supabase.co`
- Auth providers: Google, Apple 모두 활성
- Google Authorized Client IDs: `...cm6c89...` 포함
- **Migration 004 수동 실행 완료** (2026-04-21) — client_id NOT NULL + UNIQUE, deleted_at 제거, 미분류 partial unique
- 현재 테스트 유저: `linkpooltest2@gmail.com` (`id = 355d0598-e5e0-4ece-bb14-1dd03ec8e344`), plan=`pro`
- **`folders.client_id`는 integer** (UUID 아님). user 매칭은 다른 컬럼/RLS로 처리

### 3.2 디바이스
- Galaxy A52s (`R5CRB2A38HM`, Android 14) — debug 빌드 동작 확인
- iPhone (boring-km) — wifi 연결, 시뮬레이터로 보조
- Debug SHA-1: `AE:8F:D9:E5:DF:EB:B5:A0:4A:7D:DC:81:08:35:E6:C4:08:1E:36:64`
- Release SHA-1: `50:51:26:42:7A:94:28:BE:A0:CF:F9:14:3D:6B:97:87:BA:2A:F2:99`

### 3.3 git
- 브랜치: `develop`
- 원격: `https://github.com/Monday-Rocket/ac_project_app.git` (HTTPS, origin)
- `develop` = `origin/develop` (동기화됨)
- 마지막 커밋: `247a687f Merge branch 'feat/nested-folder-create' into develop`
- `feat/nested-folder-create` 브랜치는 로컬·원격 모두 삭제됨

### 3.4 Ruby/Bundler 주의사항
- 로컬 bundler: 2.5.3 (rbenv shim)
- Gemfile.lock `BUNDLED WITH` 는 **2.6.2** 로 유지해야 함 (CI/다른 개발자 환경)
- gem 업데이트 후 항상 diff 검토 → `BUNDLED WITH` 줄 수동 복구

---

## 4. 🗺️ 코드베이스 주요 진입점 (2026-04-23 기준)

### 4.1 동기화 / Pro
- `lib/provider/sync/sync_repository.dart` (522 lines) — **2-pass `upsertFolderRemote`**, `_resolveFolderOrTestHook`, dirty 관리
- `lib/provider/sync/pro_remote_hooks.dart` — 전역 훅 (Local*Repository CRUD 말단에서 호출)
- `lib/cubits/auth/auth_cubit.dart` — `planExpiresAt` 포함 state, `refreshPlan()`, free↔pro 전환 감지 → Sync 호출
- `lib/provider/auth/auth_repository.dart` — `getPlanInfo()`, `PlanInfo.effectivePlan`, Android/iOS 분기 serverClientId

### 4.2 폴더 (중첩 + 생성/조회/이동)
- `lib/provider/local/local_folder_repository.dart` (356 lines)
  - `createFolder` — 부모 존재 가드, 형제 이름 방어선, `FolderException` 계열 throw
  - `isSiblingNameTaken(int? parentId, String name)` — 미분류 제외
  - `getRootFolders()`, `getChildFolders(parentId)`, `getAllDescendants(folderId)` (재귀 CTE), `getBreadcrumb(folderId)`, `getRecursiveLinkCounts()`, `moveFolder` (순환 참조 방지)
- `lib/provider/local/folder_exceptions.dart` — `SiblingNameTakenException`, `ParentNotFoundException`, `ParentNotClassifiedException`, `UnclassifiedCreationException`
- `lib/cubits/folders/local_folders_cubit.dart` (170 lines) — `createFolder(name, {parentId}) → Future<CreateFolderResult>`
- `lib/cubits/folders/create_folder_result.dart` — sealed `Created`/`DuplicateSibling`/`ParentMissing`/`CreateFolderFailed`
- `lib/cubits/folders/folder_drill_down_cubit.dart` — 드릴다운 전용
- `lib/ui/page/my_folder/folder_drill_down_page.dart` — 드릴다운 페이지
- `lib/ui/widget/folder/folder_tree_modal.dart` — 전체 트리 모달
- `lib/ui/widget/folder/pick_folder_sheet.dart` — 폴더 선택 모달 (검색 + 최근 + 드릴다운)
- `lib/ui/widget/folder/show_create_folder_sheet.dart` (343 lines) — **신규 생성 시트** (루트/중첩 공통)
- `lib/ui/view/links/my_link_view.dart` (850 lines) — `buildChildFoldersSection`, `_buildChildFoldersHeader`, `_onAddChildFolder`
- `lib/ui/widget/dialog/bottom_dialog.dart` — `showFolderOptionsDialog`에 "하위 폴더 추가" 항목

### 4.3 시트 공개 API
```dart
/// 루트 또는 특정 부모 아래에 새 폴더를 만드는 바텀 시트.
/// 취소=null, 생성 성공=새 폴더 id 반환.
Future<int?> showCreateFolderSheet(
  BuildContext context, {
  int? initialParentId,        // 기본 부모 (null=루트)
  bool allowParentPick = true, // false면 상위 폴더 행 숨김 + 고정
});
```

### 4.4 미분류 폴더 가드
- `createFolder(isClassified=false)` → `UnclassifiedCreationException`
- 미분류를 `parent_id` 로 사용 → `ParentNotClassifiedException`
- 미분류 `deleteFolder`/`updateFolder` → `StateError`
- 미분류 `moveFolder` → `false` 반환

### 4.5 깨진 링크 체크
- `lib/cubits/links/link_check_cubit.dart` — `autoStart`, `cancel()`, `empty`/`cancelled` 상태
- `lib/util/link_checker.dart` — `LinkCheckCancelToken`, GET fallback, 1건 단위 진행률
- `lib/ui/page/my_page/my_page.dart` — `_LinkCheckDialog` / `_LinkCheckBody` / `_BrokenLinkTile` / `_LinkCheckCta`

### 4.6 SharedPreferences 동기화 관련 키
```
flutter.lp_cached_plan        ← 마지막으로 감지한 plan (free/pro)
flutter.lp_last_backup_at     ← ISO-8601
flutter.lp_remote_dirty       ← bool
flutter.lp_remote_dirty_since ← ISO-8601, dirty 시작 시각
flutter.lp_recent_folder_ids  ← 폴더 선택 모달 최근 사용 (쉼표구분)
flutter.savedLinksCount       ← 홈 상단 '추가된 링크' 계산용
```

---

## 5. 🚧 결제(RevenueCat) 연동 — 본격 착수 전 체크

이 부분은 `docs/PRO_ROADMAP.md` 섹션 5에 상세. 요약만:

| ID | 작업 | 위치 |
|---|---|---|
| C-1 | 앱 RevenueCat 인앱결제 코드 | `ac_project_app` |
| C-2 | RevenueCat 웹훅 Edge Function | `linkpool-chrome-extension/supabase/functions/` |
| C-3 | 크롬 확장 "앱에서 결제" 안내 UI | `linkpool-chrome-extension` |
| S-7 | 결제 외부 설정 9개 | `linkpool-chrome-extension/docs/PAYMENT_PLAN.md` A-1~A-9 |

**결제 붙인 이후 추가 보강** (PRO_ROADMAP 섹션 5.1~5.5):
- 구매 성공 콜백에서 `AuthCubit.refreshPlan()` 명시 호출
- `plan_expires_at` 만료 타이머 예약 (현재는 앱 시작/resumed 시에만 체크)
- 만료 직후 CRUD 처리 엣지 케이스

---

## 6. ⚠️ 알려진 엣지/한계

- **첫 Pro 전환 직후 자동 백업 완료보다 MyPage 먼저 그려지면** 캡션이 잠깐 "Pro" 만 보임. resumed 시 자동 갱신되므로 2분 내 해결.
- **`backupToRemote` 의 parent_id 2차 UPDATE 경로** (full replace)와 **`upsertFolderRemote` 2-pass** (단건)가 양쪽에서 parent_id 매핑을 보장. 단건이 부모 못 찾으면 dirty=true 유지 → 다음 백업이 해소.
- **개별 `upsertLinkRemote` 가 folder 원격 매핑 못 찾으면** dirty 만 세팅하고 skip. 다음 full replace 때 해소.
- **`_autoRestoreAttempted` 는 HomeView 인스턴스 수명 동안만 유효**. 세션 1회성 flag. 앱 재시작 시 리셋되므로 복원 실패 시 다음 시작에서 재시도.
- **url_loader_test.dart** 는 외부 네트워크 의존으로 flaky. 재실행하면 통과.
- **깨진 링크 체크 중지**: `cancel()` 호출 시 이미 진행 중이던 HTTP 요청(최대 10개, 배치 크기)은 끝까지 기다린 뒤 결과만 무시. 완전한 즉시 중단은 아님.

---

## 7. 🔁 자주 쓰는 명령어

```bash
# 로컬 개발
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze lib/
fvm flutter test

# 실기기/시뮬레이터 실행
fvm flutter devices
fvm flutter run -d R5CRB2A38HM   # Galaxy A52s
fvm flutter run -d emulator-5554

# Adb 자동 조작 (스크린샷 기반 검증)
adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png /tmp/s.png
adb shell input tap <x> <y>

# logcat (flutter 로그만)
adb logcat -d flutter:V '*:S' | sed 's/\x1b\[[0-9;]*m//g'

# 중첩 폴더 관련 테스트만
fvm flutter test test/provider/local/local_folder_repository_test.dart \
                  test/cubits/local_folders_cubit_test.dart \
                  test/provider/sync/sync_repository_upsert_test.dart \
                  test/ui/widget/folder/show_create_folder_sheet_test.dart

# Dependabot / 취약점 스캔
export PATH="/Users/kangmin/.gem/ruby/3.3.0/bin:$PATH"
(cd android && bundle-audit check)
(cd ios && bundle-audit check)
# 업데이트 후엔 BUNDLED WITH 줄을 2.6.2 로 복구할 것

# Supabase 조회 예시 (folders 테이블)
# SELECT id, name, parent_id, client_id, is_classified
# FROM folders WHERE name = 'A';
```

---

## 8. 📋 태스크 ID — PRO_ROADMAP 매칭

| ID | Phase | 제목 | 상태 |
|---|---|---|---|
| #11 | P0 | 공유 폴더 코드 잔재 제거 | **완료** |
| #12 | P1 | 로컬 SQLite 스키마 v2 — 중첩 폴더 | **완료** |
| #13 | P1 | LocalFolderRepository 계층 조회 메서드 | **완료** |
| #17 | P1 | 미분류 폴더 시스템 폴더화 | **완료** |
| #14 | P1 | 폴더 리스트 UI — 드릴다운 + 트리 모달 | **완료 (실기기 시각 검증 남음)** |
| #15 | P1 | 폴더 선택 모달 | **완료 (실기기 시각 검증 남음)** |
| #16 | P1 | 폴더 옵션 메뉴 이동 | **완료 (실기기 시각 검증 남음)** |
| #4 | P2 | Supabase migration 004 | **완료** (수동 실행됨) |
| #5 | P2 | SyncRepository 리팩토링 | **완료** |
| #6 | P2 | AuthCubit plan 캐싱 | **완료** |
| #7 | P2 | Pro CRUD 원격 쓰기 훅 | **완료** |
| #8 | P2 | dirty 플래그 보정 백업 | **완료** |
| #9 | P2 | MyPage 백업/복구 UI | **완료** (자동 우선 UX, 2.1) |
| #10 | P2 | 신규 기기 자동 복구 | **완료** (조용한 자동 복원, 2.1) |
| #18 | P2 선행 | 크롬 확장 Apple 로그인 | **완료** (실 Apple ID E2E 남음) |
| — | 신규 | 깨진 링크 체크 다이얼로그 개선 | **완료** (2.4, 실기기 시각 검증 남음) |
| — | 신규 | Dependabot 4건 대응 | **완료** (2.5, high 2건 잔여) |
| — | 신규 | 중첩 폴더 생성 Phase 1 (앱) | **완료** (2.6, 2026-04-23 머지) |
| — | 신규 | 중첩 폴더 생성 Phase 2 (Chrome) | **미착수** (1.2) |

---

## 9. 🧭 "이 문서만 읽고" 바로 이어가는 길

새 세션 시작 시 권장 순서:
1. 이 파일(`HANDOFF.md`) 끝까지 읽기
2. `git status` + `git log --oneline -10` 로 현재 작업 상태 확인 — 마지막 커밋이 `247a687f Merge branch 'feat/nested-folder-create' into develop` 라면 v3 시점과 동일
3. 실기기 있으면 섹션 1.1 체크리스트 한 번에 돌리기 — 특히 **깨진 링크 체크 다이얼로그**, 드릴다운, PickFolderSheet
4. Phase 2 Chrome 확장 작업은 `/Users/kangmin/dev/linkpool-chrome-extension`에서 별도 스펙/플랜 작성 후 진행 (섹션 1.2)
5. Apple 로그인 E2E (섹션 1.3)는 iOS 테스터 계정 준비되면 진행
6. 결제 착수는 섹션 5 + `docs/PRO_ROADMAP.md` §5 참조
7. 막히면 `docs/PRO_ROADMAP.md` 섹션 9 (결정 이력) / `docs/HANDOFF_nested_folder_create.md` (Phase 1 상세) 참조
