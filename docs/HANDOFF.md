# LinkPool 앱 — 세션 Handoff

> 작성일: 2026-04-21 (v2 — 깨진 링크 체크 다이얼로그 / 취약점 대응 후)
> 문서 성격: **세션이 초기화돼도 새 세션에서 이 파일만 읽고 바로 이어갈 수 있도록 작성된 handoff**
> 관련 문서:
> - `docs/PRO_ROADMAP.md` — P0 / P1 / P2 전체 로드맵과 설계 결정 이력
> - `linkpool-chrome-extension/docs/REMAINING_TASKS.md` — 크롬 확장 쪽 남은 작업
> - `linkpool-chrome-extension/docs/APPLE_LOGIN.md` — 크롬 확장 Apple 로그인 (코드 완료, 실 Apple ID E2E만 남음)
> - `linkpool-chrome-extension/docs/PAYMENT_PLAN.md` — 결제 외부 설정 A-1~A-9

---

## Quick Resume (재개 시 이것부터)

1. **현재 코드 상태**: P1 + P2 + 깨진 링크 체크 다이얼로그 개선까지 완료. `develop` = `origin/develop` (동기화됨).
2. **다음 해야 할 일 우선순위**:
   1. 에뮬레이터/실기기 UI 시각 검증 (섹션 1.1) — **깨진 링크 다이얼로그 포함**
   2. 실 Apple ID 수동 E2E 검증 (앱 가입 계정으로 크롬 확장 로그인) (섹션 1.2)
   3. 결제(RevenueCat) 연동 (섹션 5)
   4. 남은 Dependabot 취약점 2건 (high) — 알려주시면 대응 (섹션 1.3)
3. **빌드/테스트 현황**: `fvm flutter analyze` clean (info만), `fvm flutter test` **163/163 통과**.
4. **마지막 실동작 검증됨 (2026-04-21, 에뮬레이터 `emulator-5554`)**:
   - Google 로그인 (Android Web Client ID 전환 후)
   - Pro 전환 감지 → 자동 `backupToRemote()`
   - MyPage "Pro · 마지막 백업 04/21 16:51" 캡션
   - MyPage "지금 백업" 버튼 (동기화 밀림 배너 안의 버튼)
5. **미검증 (실기기 시각 확인 남음)**:
   - 드릴다운 페이지 (실제 중첩 폴더 데이터가 필요)
   - PickFolderSheet (폴더 이동)
   - FolderTreeModal 펼침/접힘
   - 신규 기기 자동 복원 (팝업 제거 → 조용한 복원)
   - **깨진 링크 체크 다이얼로그** (공통 톤 / 중지 버튼 / 1건 단위 진행률)

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

### 1.2 Apple 로그인 수동 E2E (P2 선행 조건 잔여)

- [ ] 앱에서 Apple로 가입한 유저 (iOS 테스터 계정) → 크롬 확장에서 Apple 로그인 → Supabase `auth.users` 같은 UUID 재사용 확인
- [ ] 로그아웃 → 재로그인 사이클 (앱 / 크롬 확장 양쪽)

### 1.3 Dependabot 취약점 잔여

이번 세션에 4건 해결 (섹션 2.4). **원격 배너 기준 2건 (high) 남음.**
- 패키지명을 알려주시면 즉시 대응 가능. bundler-audit 로컬 스캔은 0건으로 깨끗하므로 ruby-advisory-db에 아직 반영되지 않은 신규 CVE이거나 GitHub Actions 쪽일 가능성.

---

## 2. 🎯 이번 세션까지 바뀐 정책 / 동작 (중요)

### 2.1 백업/복원 UX: **자동 우선 + 필요할 때만 UI 등장** (유지)

- MyPage의 상시 노출되던 백업&복원 카드 **제거**
- 계정 영역 아래 한 줄 캡션: `Pro · 마지막 백업 MM/DD HH:mm`
- 신규 기기 자동 복구 팝업 **제거** → 조건(Pro + 로컬 links=0 + 원격 백업 있음) 만족 시 **조용히** `restoreFromRemote()`
- 동기화 밀림 배너: `isDirty==true` 가 **30분 이상 지속**된 경우에만 MyPage 상단에 노란 배너 + `지금 백업` 버튼

관련 커밋: `3afaa098 feat: 백업/복원 UI 자동 우선 전환`

### 2.2 Google 로그인 — Web Client ID로 전환 (유지)

- Android serverClientId를 Chrome Extension과 공유하는 **Web application 타입** Client ID 사용:
  `310694628669-cm6c89tss9g8vbp5dtd173gpe64bs0on.apps.googleusercontent.com`
- 이전 Android 타입 Client ID를 쓰면 Credential Manager가 `[28444] Developer console is not set up correctly` 를 뱉음.
- Supabase Auth → Providers → Google → Authorized Client IDs 에 이 Web Client ID 등록 완료.

관련 커밋: `03da1de9 fix: Android Google 로그인을 Web Client ID 기반으로 전환`

### 2.3 HomeView Provider 스코프 (유지)

`AuthCubit` lifecycle 접근을 `Builder` 로 감싼 innerCtx 에서 ref 캡처. lifecycle 훅은 캡처된 ref 사용.
관련 커밋: `2fe83395 fix: AuthCubit provider 접근 불가 문제 해결 (HomeView self-scope)`

### 2.4 🆕 깨진 링크 체크 다이얼로그 — 공통 톤 + 중지 + 1건 단위 진행률

- **UI**: `AlertDialog` → 프로젝트 공통 `Dialog` 카드로 교체 (흰 배경, 16.w radius, 우상단 `Icons.close_rounded`, primary600 CTA, Pretendard)
- **Cubit**: 생성자에서 `autoStart` 로 즉시 검사 시작 (dialog 생성 ↔ `checkAllLinks` race 제거). `empty` / `cancelled` 상태 추가. `cancel()` 메서드로 즉시 `cancelled` emit + 내부 토큰 cancel.
- **Checker**:
  - `LinkCheckCancelToken` 으로 배치 단위 취소 지원
  - HEAD 405/403/501 → GET fallback (네이버/유튜브 등 HEAD 차단 사이트 false-positive 방지)
  - HEAD 예외 → GET 재시도
  - 잘못된 URL(스킴 없음, parse 실패)은 HTTP 요청 없이 즉시 실패
  - `onProgress` 가 URL 1개 완료마다 1씩 증가 (이전: 배치 10개 단위 점프). 원본 URL 순서는 보존.
- **CTA 분기**: `checking/initial` 일 땐 **"중지"** (OutlinedButton, `cubit.cancel()`), 그 외엔 **"확인"** (primary600, Navigator pop). `PopScope.canPop` 은 `!checking && !initial` 일 때만 true.
- **테스트**: `test/util/link_checker_test.dart` 10건, `test/cubits/link_check_cubit_test.dart` 7건 신규. 전체 **163/163 통과**.

관련 커밋: `8853058f feat: 깨진 링크 체크 다이얼로그 개선 (공통 톤 + 중지 버튼 + 1건 단위 진행률)`

### 2.5 🆕 Dependabot 취약점 대응 (4건 해결, 2건 잔여)

| gem | 이전 | 이후 | CVE |
|---|---|---|---|
| faraday | 1.10.4 | 1.10.5 | CVE-2026-25765 SSRF (GHSA-33mh-2634-fwr2, Medium) |
| json | 2.18.1 | 2.19.4 | CVE-2026-33210 format string injection (GHSA-3m6g-2423-7cp3) |
| addressable | 2.8.8 | 2.9.0 | Dependabot alert (High) |

- `android/Gemfile.lock` + `ios/Gemfile.lock` 양쪽 동시 적용
- **주의**: `bundle update` 시 `BUNDLED WITH` 가 로컬 bundler 버전(2.5.3)으로 다운그레이드되는 현상 있음 → 반드시 `2.6.2` 로 복구 후 커밋
- `bundle-audit check` 기준 android/ios 모두 "No vulnerabilities found"

관련 커밋:
- `ebb5c083 chore: fastlane 의존성 취약점 대응 (faraday, json)`
- `1ce01129 chore: addressable 2.8.8 → 2.9.0 (Dependabot alert 대응)`

원격 배너 기준 6 → 2 (high) 로 감소. 나머지 2건은 패키지명 확인 후 대응 예정.

---

## 3. 🔑 현재 원격/환경 상태 스냅샷

### 3.1 Supabase
- 프로젝트 URL: `https://gystdpdelnfblgyeckth.supabase.co`
- Auth providers: Google, Apple 모두 활성
- Google Authorized Client IDs: `...cm6c89...` 포함
- **Migration 004 수동 실행 완료** (2026-04-21) — client_id NOT NULL + UNIQUE, deleted_at 제거, 미분류 partial unique
- 현재 테스트 유저: `linkpooltest2@gmail.com` (`id = 355d0598-e5e0-4ece-bb14-1dd03ec8e344`), plan=`pro`, `plan_expires_at = NOW() + 1 year`

### 3.2 에뮬레이터/디바이스
- Android 에뮬레이터 `emulator-5554` — debug 빌드
- Debug SHA-1: `AE:8F:D9:E5:DF:EB:B5:A0:4A:7D:DC:81:08:35:E6:C4:08:1E:36:64`
- Release SHA-1: `50:51:26:42:7A:94:28:BE:A0:CF:F9:14:3D:6B:97:87:BA:2A:F2:99`

### 3.3 git
- 브랜치: `develop`
- 원격: `git@github-personal:Monday-Rocket/ac_project_app.git` (개인 계정 SSH host)
- `develop` = `origin/develop` (동기화됨)
- 마지막 커밋: `1ce01129 chore: addressable 2.8.8 → 2.9.0 (Dependabot alert 대응)`

### 3.4 Ruby/Bundler 주의사항
- 로컬 bundler: 2.5.3 (rbenv shim)
- Gemfile.lock `BUNDLED WITH` 는 **2.6.2** 로 유지해야 함 (CI/다른 개발자 환경)
- gem 업데이트 후 항상 diff 검토 → `BUNDLED WITH` 줄 수동 복구

---

## 4. 🗺️ 코드베이스 주요 진입점 (2026-04-21 기준)

### 4.1 핵심 파일 (바뀐 부분 포함)
- `lib/provider/sync/sync_repository.dart` — 백업/복구 + 원격 upsert/delete + dirty 관리
- `lib/provider/sync/pro_remote_hooks.dart` — 전역 훅 (Local*Repository CRUD 말단에서 호출)
- `lib/cubits/auth/auth_cubit.dart` — `planExpiresAt` 포함 state, `refreshPlan()`, free↔pro 전환 감지 → Sync 호출
- `lib/provider/auth/auth_repository.dart` — `getPlanInfo()`, `PlanInfo.effectivePlan`, Android/iOS 분기 serverClientId
- `lib/cubits/folders/local_folders_cubit.dart` — `rootsOnly` 플래그로 중첩/플랫 모드 분기
- `lib/cubits/folders/folder_drill_down_cubit.dart` — 드릴다운 전용 Cubit (`folderId` 기반)
- `lib/ui/page/my_folder/folder_drill_down_page.dart` — 드릴다운 페이지 (브레드크럼 + 하위 폴더 섹션 + 직접 링크 섹션)
- `lib/ui/widget/folder/folder_tree_modal.dart` — 전체 트리 모달
- `lib/ui/widget/folder/pick_folder_sheet.dart` — 폴더 선택 모달 (검색 + 최근 + 드릴다운)
- `lib/ui/view/home_view.dart` — provider 구성 + lifecycle + `_maybeAutoRestore`(조용한 복원)
- `lib/ui/page/my_page/my_page.dart` — `_ProCaption` + `_SyncIssueBanner` + **`_LinkCheckDialog` / `_LinkCheckBody` / `_BrokenLinkTile` / `_LinkCheckCta` (🆕)**
- `lib/cubits/links/link_check_cubit.dart` — 🆕 `autoStart`, `cancel()`, `empty`/`cancelled` 상태
- `lib/util/link_checker.dart` — 🆕 `LinkCheckCancelToken`, GET fallback, 1건 단위 진행률

### 4.2 중첩 폴더 SQLite 계층 API (`LocalFolderRepository`)
- `getRootFolders()`, `getChildFolders(parentId)`, `getAllDescendants(folderId)` (재귀 CTE)
- `getBreadcrumb(folderId)`, `getRecursiveLinkCounts()`, `moveFolder(folderId, newParentId)` (순환 참조 방지)

### 4.3 미분류 폴더 가드
- `createFolder(isClassified=false)` → `StateError`
- 미분류를 `parent_id` 로 사용 → `StateError`
- 미분류 `deleteFolder`/`updateFolder` → `StateError`
- 미분류 `moveFolder` → `false` 반환

### 4.4 SharedPreferences 동기화 관련 키
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
- **`backupToRemote` 의 parent_id 2차 UPDATE 경로**: 개별 folder upsert (`upsertFolderRemote`) 에서는 parent_id 를 항상 `null` 로 넣고, 정확한 매핑은 `backupToRemote` 의 full replace 시에만 해결. 실시간 정확도는 dirty 보정 백업에 의존.
- **개별 `upsertLinkRemote` 가 folder 원격 매핑 못 찾으면** dirty 만 세팅하고 skip. 다음 full replace 때 해소.
- **`_autoRestoreAttempted` 는 HomeView 인스턴스 수명 동안만 유효**. 세션 1회성 flag. 앱 재시작 시 리셋되므로 복원 실패 시 다음 시작에서 재시도.
- **url_loader_test.dart** 는 외부 네트워크 의존으로 flaky. 재실행하면 통과.
- **🆕 깨진 링크 체크 중지**: `cancel()` 호출 시 이미 진행 중이던 HTTP 요청(최대 10개, 배치 크기)은 끝까지 기다린 뒤 결과만 무시. 완전한 즉시 중단은 아님.

---

## 7. 🔁 자주 쓰는 명령어

```bash
# 로컬 개발
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze lib/
fvm flutter test

# 에뮬레이터 실행
fvm flutter run -d emulator-5554

# Adb 자동 조작 (스크린샷 기반 검증)
adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png /tmp/s.png
adb shell input tap <x> <y>

# logcat (flutter 로그만)
adb logcat -d flutter:V '*:S' | sed 's/\x1b\[[0-9;]*m//g'

# 개인 계정 git push (이 레포 정책)
git config user.name "boring-km"
git config user.email "kms0644804@naver.com"
git remote -v  # origin이 github-personal:Monday-Rocket/... 인지 확인
git push origin develop:develop

# Dependabot / 취약점 스캔
export PATH="/Users/kangmin/.gem/ruby/3.3.0/bin:$PATH"
(cd android && bundle-audit check)
(cd ios && bundle-audit check)
# 업데이트 후엔 BUNDLED WITH 줄을 2.6.2 로 복구할 것
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
| #9 | P2 | MyPage 백업/복구 UI | **완료** (자동 우선 UX 로 재설계됨, 2.1 참조) |
| #10 | P2 | 신규 기기 자동 복구 | **완료** (팝업 제거 → 조용한 자동 복원, 2.1 참조) |
| #18 | P2 선행 | 크롬 확장 Apple 로그인 | **완료** (실 Apple ID E2E 남음) |
| — | 신규 | 깨진 링크 체크 팝업 공통 톤 + 동작 + 중지 + 진행률 | **완료** (2.4, 실기기 시각 검증 남음) |
| — | 신규 | Dependabot faraday/json/addressable 대응 | **완료** (2.5, high 2건 잔여) |

---

## 9. 🧭 "이 문서만 읽고" 바로 이어가는 길

새 세션 시작 시 권장 순서:
1. 이 파일(`HANDOFF.md`) 끝까지 읽기
2. `git status` + `git log --oneline -10` 로 현재 작업 상태 확인
3. 실기기 있으면 섹션 1.1 체크리스트 한 번에 돌리기 — 특히 **깨진 링크 체크 다이얼로그** (중지 버튼, 1/N 진행률, empty/cancelled 상태)
4. Apple 로그인 E2E (섹션 1.2)는 iOS 테스터 계정 준비되면 진행
5. 결제 착수는 섹션 5 + `docs/PRO_ROADMAP.md` §5 참조
6. 막히면 `docs/PRO_ROADMAP.md` 섹션 9 (결정 이력) / 섹션 10 (코드 스냅샷) 참조
