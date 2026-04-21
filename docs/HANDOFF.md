# LinkPool 앱 — 세션 Handoff

> 작성일: 2026-04-21 (세션 종료 시점)
> 문서 성격: **세션이 초기화돼도 새 세션에서 이 파일만 읽고 바로 이어갈 수 있도록 작성된 handoff**
> 관련 문서:
> - `docs/PRO_ROADMAP.md` — P0 / P1 / P2 전체 로드맵과 설계 결정 이력
> - `linkpool-chrome-extension/docs/REMAINING_TASKS.md` — 크롬 확장 쪽 남은 작업
> - `linkpool-chrome-extension/docs/APPLE_LOGIN.md` — 크롬 확장 Apple 로그인 (코드 완료, 실 Apple ID E2E만 남음)

---

## Quick Resume (재개 시 이것부터)

1. **현재 코드 상태**: P1 + P2 구현 완료. `develop` 브랜치가 `origin/develop`보다 **4 커밋 앞섬** 상태 (푸시 필요).
2. **다음 해야 할 일 우선순위**:
   1. `깨진 링크 체크` 팝업 공통 톤으로 교체 + 동작 불량 수정 (섹션 1)
   2. 에뮬레이터 UI 실기기 검증 (드릴다운/트리 모달/폴더 이동/백업 UX)
   3. 실 Apple ID 수동 E2E 검증 (앱 가입 계정으로 크롬 확장 로그인)
   4. 결제(RevenueCat) 연동 — 섹션 5 이후 옵션
3. **빌드/테스트 현황**: `fvm flutter analyze` clean (info만), `fvm flutter test` 146/146 통과.
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

---

## 1. 🔧 남은 작업 — 구체적

### 1.1 🐛 `깨진 링크 체크` 팝업: 공통 톤 미적용 + 동작 불량 — **우선 처리**

#### 증상
- **동작 안 함**: MyPage → `깨진 링크 체크` 메뉴 탭 시 팝업은 뜨는데 검사가 진행되지 않는다는 사용자 보고 (2026-04-21 세션).
- **디자인 비표준**: 앱 공용 `Dialog` 스타일(`showPopUp` / `deleteFolderDialog` 패턴)과 다른 Material 기본 `AlertDialog` shell 사용 중.

#### 현재 코드 위치
- `lib/ui/page/my_page/my_page.dart:258` `_showLinkCheckDialog()` — `AlertDialog` + `BlocBuilder<LinkCheckCubit, ...>` 직조
- `lib/cubits/links/link_check_cubit.dart` — `LinkCheckCubit` 구현, `checkAllLinks()`가 `LocalLinkRepository.getAllLinks()` + `LinkChecker.checkLinks()`를 호출
- `lib/util/link_checker.dart` — HTTP HEAD 배치 체크(10개씩, 5초 타임아웃)

#### 동작 불량 — 조사 가설 (확정 전)
세션 중 재현을 정확히 못 본 상태이므로 가설만 나열:

| 가설 | 확인 방법 |
|---|---|
| **로컬 링크 0건**이라 "검사 중" 후 바로 "모든 링크 정상" 으로 끝나서 사용자 입장에서 "동작 안 함"처럼 보임 | `SELECT COUNT(*) FROM link` (앱 로컬 SQLite) 먼저 확인 |
| `http.head()` 가 일부 서버에서 405/타임아웃 → 배치가 block | logcat 에서 `LinkCheckCubit` 쪽 Flutter 로그 확인 |
| Cubit 생성 직후 `cubit.checkAllLinks()` 호출 순서 race (dialog 생성 → provider value 주입 → `checkAllLinks` 호출 사이 상태) | dialog가 실제로 `checking` 상태로 빌드되는지 스크린샷으로 확인 |

#### 권장 수정 범위
1. **공통 톤으로 교체** — `deleteFolderDialog`(center_dialog.dart:249) 스타일을 기준으로 커스텀 `Dialog` 껍데기 사용:
   - 흰 배경 + 16.w radius + 20.w 패딩 + 상단 아이콘 원형 배경(primary100) + Pretendard 18sp bold 제목 + grey500 14sp 본문 + primary600 CTA 48.w 높이
   - 오른쪽 상단 close 버튼(`Assets.images.btnXPrimary`) 또는 탭 외부 dismiss
2. **동작 버그 진단 & 수정**:
   - 로컬 링크 0건일 때 "검사할 링크가 없습니다" 별도 안내 추가
   - Cubit 생성 직후 `checkAllLinks` 호출 대신 Cubit 생성자 내부에서 자동 시작하는 쪽이 race 제거에 안전
   - `LinkChecker._checkUrl` 에 HEAD 실패 시 GET fallback 고려 (일부 서버 HEAD 불허)

#### 참고: 공통 톤 레퍼런스
- `lib/ui/widget/dialog/center_dialog.dart:13` `showPopUp()` — 일반 알림
- `lib/ui/widget/dialog/center_dialog.dart:249` `deleteFolderDialog()` — 위험 액션 확인
- 두 패턴 모두 `Dialog` 흰 카드 + Pretendard + primary600 CTA.

### 1.2 🧹 공통 팝업 미사용 위치 전수 점검

현재 `AlertDialog` 원본을 그대로 쓰는 지점을 grep 해둔 결과 (2026-04-21):

```
lib/ui/page/my_page/my_page.dart:270    ← 깨진 링크 체크 (1.1 항목)
lib/ui/widget/dialog/center_dialog.dart:254  ← deleteFolderDialog, 내부 커스터마이징 완료. 유지.
```

**조치 대상은 1건 (`my_page.dart:270`).** 다른 `showDialog` / `showModalBottomSheet` 사용처는 공통 헬퍼 경유이거나 이미 톤이 맞춰져 있음.

### 1.3 실기기 시각 검증 체크리스트

에뮬레이터에서 **`adb` 자동화**로는 조작 가능하지만, 결국 사람 눈으로 확인해야 하는 항목:

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

### 1.4 Apple 로그인 수동 E2E (P2 선행 조건 잔여)

- [ ] 앱에서 Apple로 가입한 유저 (iOS 테스터 계정) → 크롬 확장에서 Apple 로그인 → Supabase `auth.users` 같은 UUID 재사용 확인
- [ ] 로그아웃 → 재로그인 사이클 (앱 / 크롬 확장 양쪽)

---

## 2. 🎯 이번 세션에서 바뀐 정책 / 동작 (중요)

### 2.1 백업/복원 UX: **자동 우선 + 필요할 때만 UI 등장**

- **MyPage의 상시 노출되던 백업&복원 카드 → 제거**
- 계정 영역 아래 한 줄 캡션: `Pro · 마지막 백업 MM/DD HH:mm`
- 신규 기기 자동 복구 팝업 **제거** → 조건(Pro + 로컬 links=0 + 원격 백업 있음) 만족 시 **조용히** `restoreFromRemote()`
- 동기화 밀림 배너: `isDirty==true` 가 **30분 이상 지속**된 경우에만 MyPage 상단에 노란 배너 + `지금 백업` 버튼 노출 (백업 성공 시 자동 소멸)

관련 커밋: `3afaa098 feat: 백업/복원 UI 자동 우선 전환`

### 2.2 Google 로그인 — Web Client ID로 전환

- Android serverClientId를 Chrome Extension과 공유하는 **Web application 타입** Client ID로 변경
  - `310694628669-cm6c89tss9g8vbp5dtd173gpe64bs0on.apps.googleusercontent.com`
- 이전 Android 타입 Client ID(`...10m2vjbei...`)를 쓰면 Credential Manager가 `[28444] Developer console is not set up correctly` 를 뱉음
- Supabase Auth → Providers → Google → Authorized Client IDs 에 이 Web Client ID 등록 완료

관련 커밋: `03da1de9 fix: Android Google 로그인을 Web Client ID 기반으로 전환`

### 2.3 HomeView Provider 스코프 버그 수정

- `AuthCubit` 이 `MultiBlocProvider` 의 child 안에 있는데 `HomeView` 의 `initState`/`didChangeAppLifecycleState` 에서 `context.read<AuthCubit>()` 을 바로 호출 → `ProviderNotFoundError`
- **수정**: `Builder` 로 감싸 provider 하위 `innerCtx` 에서 `_authCubitRef` 캡처. lifecycle 훅은 캡처된 ref 사용.

관련 커밋: `2fe83395 fix: AuthCubit provider 접근 불가 문제 해결 (HomeView self-scope)`

---

## 3. 🔑 현재 원격/환경 상태 스냅샷

### 3.1 Supabase
- 프로젝트 URL: `https://gystdpdelnfblgyeckth.supabase.co`
- Auth providers: Google, Apple 모두 활성
- Google Authorized Client IDs: 위 `...cm6c89...` 포함
- **Migration 004 수동 실행 완료** (2026-04-21) — client_id NOT NULL + UNIQUE, deleted_at 제거, 미분류 partial unique
- 현재 테스트 유저: `linkpooltest2@gmail.com` (`id = 355d0598-e5e0-4ece-bb14-1dd03ec8e344`), plan=`pro`, `plan_expires_at = NOW() + 1 year`

### 3.2 에뮬레이터/디바이스
- Android 에뮬레이터 `emulator-5554` — debug 빌드
- Debug SHA-1 (Google Cloud Console Android OAuth Client 에 등록되어 있어야 함):
  - Debug: `AE:8F:D9:E5:DF:EB:B5:A0:4A:7D:DC:81:08:35:E6:C4:08:1E:36:64`
  - Release: `50:51:26:42:7A:94:28:BE:A0:CF:F9:14:3D:6B:97:87:BA:2A:F2:99`

### 3.3 git
- 브랜치: `develop`
- 원격: `git@github-personal:Monday-Rocket/ac_project_app.git` (개인 계정 SSH host)
- **로컬 4 커밋 앞섬** (세션 종료 시점):
  - `03da1de9 fix: Android Google 로그인 Web Client ID`
  - `2fe83395 fix: HomeView AuthCubit provider self-scope`
  - `3980150f style: 자동 복구 다이얼로그 디자인 정리` (이후 `3afaa098` 에서 이 다이얼로그 자체가 제거됨 — 코드상 흔적은 없지만 커밋 히스토리엔 남음)
  - `3afaa098 feat: 백업/복원 UI 자동 우선 전환`

---

## 4. 🗺️ 코드베이스 주요 진입점 (2026-04-21 기준)

### 4.1 신규/변경된 핵심 파일
- `lib/provider/sync/sync_repository.dart` — 백업/복구 + 원격 upsert/delete + dirty 관리. `backupToRemote`, `restoreFromRemote`, `purgeRemote`, `hasRemoteBackup`, `isDirty`, `getDirtySince`, `getLastBackupAt`
- `lib/provider/sync/pro_remote_hooks.dart` — 전역 훅. `configure(isPro, upsert/deleteFolder, upsert/deleteLink)`. Local*Repository 의 CRUD 말단에서 `onFolderUpserted` / `onLinkDeleted` 등 호출
- `lib/cubits/auth/auth_cubit.dart` — `planExpiresAt` 포함 state, `refreshPlan()`, free↔pro 전환 감지 → Sync 호출
- `lib/provider/auth/auth_repository.dart` — `getPlanInfo()`, `PlanInfo.effectivePlan`, Android/iOS 분기 serverClientId
- `lib/cubits/folders/local_folders_cubit.dart` — `rootsOnly` 플래그로 중첩/플랫 모드 분기
- `lib/cubits/folders/folder_drill_down_cubit.dart` — 드릴다운 전용 Cubit (`folderId` 기반)
- `lib/ui/page/my_folder/folder_drill_down_page.dart` — 드릴다운 페이지 (브레드크럼 + 하위 폴더 섹션 + 직접 링크 섹션)
- `lib/ui/widget/folder/folder_tree_modal.dart` — 전체 트리 모달
- `lib/ui/widget/folder/pick_folder_sheet.dart` — 폴더 선택 모달 (검색 + 최근 + 드릴다운)
- `lib/ui/view/home_view.dart` — provider 구성 + lifecycle + `_maybeAutoRestore`(조용한 복원)
- `lib/ui/page/my_page/my_page.dart` — `_ProCaption`(한 줄 캡션) + `_SyncIssueBanner`(dirty 지속 시 배너)

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
| — | **신규** | 깨진 링크 체크 팝업 공통 톤 + 동작 버그 수정 | **미착수** (1.1) |

---

## 9. 🧭 "이 문서만 읽고" 바로 이어가는 길

새 세션 시작 시 권장 순서:
1. 이 파일(`HANDOFF.md`) 끝까지 읽기
2. `git status` + `git log --oneline -10` 로 현재 작업 상태 확인
3. 1.1 (깨진 링크 팝업) 부터 시작 — `my_page.dart:258` + `center_dialog.dart:13,249` 비교하면 변경 범위 바로 보임
4. 1.3 체크리스트는 실기기 손에 있을 때 한 번에 돌리기
5. 막히면 `docs/PRO_ROADMAP.md` 섹션 9 (결정 이력) / 섹션 10 (코드 스냅샷) 참조
