# 중첩 폴더 생성 기능 — 세션 재개용 HANDOFF

> **작성일**: 2026-04-23
> **문서 성격**: **handoff 문서** — 세션 초기화 후 새 세션에서 이 문서만 읽고 즉시 구현을 이어갈 수 있도록 작성됨.
> **관련 문서** (모두 이 저장소 내부):
> - 설계 스펙: `docs/superpowers/specs/2026-04-23-nested-folder-create-design.md`
> - 구현 계획: `docs/superpowers/plans/2026-04-23-nested-folder-create-plan.md`
> - 프로젝트 가이드: `CLAUDE.md`

---

## Quick Resume (세션 재개 시 이것부터 읽음)

1. **현재 진행 상황**: Phase 1의 **Task 1~7 완료, Task 8·9 미완료**. `feat/nested-folder-create` 브랜치에 13개 커밋 누적.
2. **다음 할 일**:
   - **Task 8** (선택) — `integration_test/nested_folder_create_test.dart` 작성 + 로컬 실기기/시뮬레이터로 실행
   - **Task 9** — Pro 실기기 수동 검증 체크리스트 완주 (Supabase Studio 병행 필요)
   - 그 후 develop으로 PR
3. **환경 전제**:
   - Flutter 3.41.7 (FVM), Dart 3 sealed class 지원됨
   - 작업 브랜치 `feat/nested-folder-create` 체크아웃 상태
   - `git stash@{0}`에 세션 시작 전 작업하던 `ios/Runner.xcodeproj/project.pbxproj` 변경사항이 남아있음 (이번 작업과 무관)
4. **막힐 때**:
   - "내가 지금 뭘 바꿨지?" → 섹션 4 "완료된 작업 스냅샷"
   - "설계 결정이 왜 이렇지?" → 섹션 6 "결정 이력 요약" 또는 설계 스펙 문서
   - "실제 코드 어디에 있지?" → 섹션 5 "코드베이스 스냅샷"
   - Task 8/9 실행 가이드 → 섹션 3

---

## 0. 배경 & 현재 상태

### 무엇을 만들고 있나

링크풀(LinkPool) 앱과 Chrome 확장에 **"특정 폴더 아래에 새 폴더를 만드는"** 기능을 추가하는 작업. 현재 앱의 읽기/이동 UI는 이미 중첩 폴더를 완전히 지원하지만, **생성 진입점만 루트 전용**이라 중첩 구조를 의도적으로 설계할 수 없는 상태였다.

### Phase 구조

- **Phase 1 — Flutter 앱**: 이번 세션에서 진행. Task 1~7 완료 (자동), Task 8~9 남음.
- **Phase 2 — Chrome 확장**: Phase 1 종료 후 **별도 스펙/플랜으로 후속 작성**. 이번 세션 범위 아님.

### 왜 Phase 1 자동 실행을 Task 7에서 멈췄나

사용자가 세션 시작 시 **"Task 7까지 자동, Task 8(E2E)·Task 9(Pro 수동 검증)는 사용자 직접"**으로 명시적으로 합의함. Task 8은 실기기/시뮬레이터 의존이 크고, Task 9는 Pro 계정과 Supabase Studio 관찰이 필요해 자동화 어려움.

### 작업 방식

Subagent-Driven Development (superpowers 스킬) 워크플로우. 각 Task마다:
1. 구현자 서브에이전트 디스패치 → 구현 + 테스트 + 커밋 + 자체 리뷰
2. Spec 준수 리뷰어 서브에이전트 디스패치 → 스펙과 대조
3. Code quality 리뷰어 서브에이전트 디스패치 → 코드 품질 점검
4. 문제 있으면 수정 커밋 추가

---

## 1. Phase 1 개요 (Task 1~9)

| # | 내용 | 상태 | 커밋 |
|---|---|---|---|
| 1 | `SyncRepository.upsertFolderRemote` 2-pass 버그 수정 + `upsertLinkRemote` 예외 가드 | ✅ | `642d194e`, `9acfc97a` |
| 2 | `LocalFolderRepository.isSiblingNameTaken` + `createFolder` 부모 존재 가드 | ✅ | `4a2707a8`, `5abd40ce` |
| 3 | `CreateFolderResult` sealed + `LocalFoldersCubit.createFolder(name, {parentId})` | ✅ | `f1e656db`, `d2b0d602` |
| 4 | `showCreateFolderSheet` 신규 위젯 (dead code) + 해피패스 테스트 | ✅ | `b3eb3852`, `acdfca7f` |
| 5 | 구 `showAddFolderDialog` 호출부 전환 + 삭제 + mounted/토스트 순서 교정 | ✅ | `478da45b`, `6c953dde` |
| 6 | `MyLinkView` "하위 폴더 (N)" 헤더 `+` 버튼 + 빈 상태 문구 | ✅ | `9c57b52f` |
| 7 | `showFolderOptionsDialog`에 "하위 폴더 추가" 항목 | ✅ | `7f60eab8`, `d4f5bbd4` |
| 8 | E2E 골든 플로우 (`integration_test/`) | ⏳ 미완료 | — |
| 9 | Pro 실기기 수동 검증 체크리스트 | ⏳ 미완료 | — |

Task 1~7은 **독립 머지 가능** 원칙으로 분리된 커밋 단위.

---

## 2. 완료된 것의 사용자 체감 상태

**앱 실행 시**:

- **내 폴더 탭** 하단 "+ 새 폴더" → 새 시트 열림 → 루트 생성 + 신규 폴더로 자동 이동. 토스트는 이동 전 표시됨 (정정 반영됨, commit `6c953dde`).
- **폴더 상세 화면 (`MyLinkView`)**에서 "하위 폴더 (N)" 섹션이 **항상 노출**. 자식 0개면 "하위 폴더 없음" 문구. 섹션 헤더 우측에 `+` 아이콘 (key `my_link_view_add_child_folder`). 탭하면 현재 폴더를 `initialParentId`로 시트 열림. 생성 성공 시 토스트 + 자식 리스트 즉시 갱신. 사용자는 부모 화면에 머무름.
- **우상단 `...` 옵션 시트**에 "**하위 폴더 추가**" 항목이 `폴더명 변경` 위에 추가됨.
- **공유/업로드 플로우**에서 "+ 새 폴더" → `showCreateFolderSheet(allowParentPick: false)`로 루트 고정 생성 (기존 동작 유지).
- **미분류 폴더** 상세 화면에서는 "하위 폴더" 섹션 자체가 숨겨져 중첩 생성 경로가 봉쇄됨. 옵션 시트도 띄워지지 않는 기존 가드 유지.

**Pro 사용자**: 단건 업서트 경로에서 `parent_id`가 2-pass로 올바르게 왕복됨 (자동 테스트 불가, Task 9에서 검증 필요).

**폐기된 것**: `lib/ui/widget/add_folder/show_add_folder_dialog.dart` 삭제, `bottom_dialog.dart`의 `saveEmptyFolder`/`runCallback` 삭제.

**유지된 것**: `lib/cubits/folders/folder_name_cubit.dart`는 `show_rename_folder_dialog.dart`가 여전히 사용 중이라 **삭제 안 함** (스펙/계획 양쪽에 명시됨, 후속 리팩터링 이슈).

---

## 3. 남은 작업 실행 가이드 (Task 8·9)

### Task 8 — E2E 골든 플로우

**목표**: `루트 폴더 개발 생성` → `개발 진입` → `+ 하위 폴더` → `React 입력 + 생성` → `개발 상세에 하위 폴더 (1) > React` 노출 → `React 진입` → 브레드크럼 `루트 > 개발 > React`.

**실행 전 확인**:
- [ ] `integration_test` 패키지가 `pubspec.yaml`의 dev_dependencies에 있는지. 있으면 바로 진행. `integration_test/login_test.dart`가 이미 있으므로 있음.
- [ ] 실기기 또는 시뮬레이터 연결됨 (`fvm flutter devices`로 확인)

**구현 순서**:

1. `integration_test/nested_folder_create_test.dart` 작성. 시나리오는 계획서 Task 8 Step 2의 예시 그대로. 앱의 네비게이션(홈 → 내 폴더 탭) 실제 텍스트/아이콘을 먼저 `integration_test/login_test.dart`에서 확인해 시나리오 텍스트 맞추기.
2. **핵심 위젯 key들** (실제 사용 가능):
   - `create_folder_name_field` — 시트의 이름 입력 필드
   - `create_folder_submit` — 시트의 "폴더 생성하기" 버튼
   - `create_folder_done_text` — 시트 우상단 "완료" 텍스트
   - `create_folder_parent_row` — 시트의 상위 폴더 선택 행
   - `my_link_view_add_child_folder` — MyLinkView "하위 폴더 (N)" 헤더의 `+` 버튼

3. 로컬 실행:
   ```
   fvm flutter test integration_test/nested_folder_create_test.dart
   ```

4. 커밋:
   ```
   git add integration_test/nested_folder_create_test.dart
   git commit -m "test(folder): 중첩 폴더 생성 E2E 골든 플로우"
   ```

**막힐 때**: `find` 실패 시 실제 앱을 시뮬레이터로 띄워서 각 화면의 텍스트/아이콘을 먼저 확인. `find.byKey`는 위에 나열된 key들로 이미 접근 가능.

### Task 9 — Pro 수동 검증 체크리스트

**실행 전 확인**:
- [ ] Task 1~8 구현 완료 커밋됨
- [ ] Supabase 콘솔 접근 가능
- [ ] Pro 계정 로그인 가능한 실기기 준비됨

**체크리스트** (계획서 Task 9 원본):

- [ ] Pro 로그인 → 루트 폴더 `A` 생성 → Supabase Studio `folders` 테이블에서 `client_id=<A.id>`, `parent_id=null`, `is_classified=true` 확인
- [ ] 앱에서 `A` 진입 → `+ 하위 폴더` 탭 → `B` 생성 → Supabase에서 `B` 레코드의 `parent_id`가 `A의 uuid`와 일치하는지 확인 (**2-pass가 실제로 동작하는지 검증하는 핵심 항목**)
- [ ] 비행기 모드 on → `B` 아래 `C` 생성 → 비행기 모드 off → (앱 재시작 또는 자동 보정 타이밍 대기 후) Supabase에 `C`가 `parent_id=B의 uuid`로 업서트됐는지 확인
- [ ] **고아 부모 시나리오**: Supabase Studio에서 `A` 레코드 직접 삭제 → 앱에서 `A` 아래 `D` 생성 → 로컬은 `D` 존재, 원격은 `D` 없음, `dirty=true` 유지 → 수동 백업/머지 후 `D` 복원 확인

**완료 후**:
- 결과를 PR 설명에 캡처로 기재
- 스펙 문서 `Verification 체크리스트` 7개 항목 전부 체크
- develop으로 PR 생성

---

## 4. 완료된 작업 스냅샷 (커밋별)

`git log develop..HEAD --pretty=format:"%h %s"` 결과 (최신 → 과거):

```
d4f5bbd4 style(folder): 하위 폴더 추가 토스트의 folder.name null 방어를 Task 6과 일관
7f60eab8 feat(folder): 폴더 옵션 시트에 '하위 폴더 추가' 항목 추가
9c57b52f feat(folder): MyLinkView에 '하위 폴더 추가' 진입점 + 빈 상태 문구
6c953dde fix(folder): my_folder_page 새 폴더 생성 onTap의 mounted 가드 + 토스트 순서 교정
478da45b refactor(folder): showAddFolderDialog → showCreateFolderSheet 호출부 전환
acdfca7f test(folder): showCreateFolderSheet 생성 성공 경로 테스트 추가
b3eb3852 feat(folder): showCreateFolderSheet 신규 — 루트/중첩 폴더 생성 시트
d2b0d602 refactor(folder): StateError → 타입 있는 FolderException 계열로 전환
f1e656db feat(folder): Cubit.createFolder를 parentId 지원 + CreateFolderResult 반환
5abd40ce fix(folder): isSiblingNameTaken이 미분류 폴더를 제외 + 중복 테스트 정리
4a2707a8 feat(folder): 형제 범위 중복 검사 + 부모 존재 가드 추가
9acfc97a test(sync): upsertFolderRemote 테스트에 실제 userId 세팅 — parentId=null 분기 실검증
642d194e fix(sync): upsertFolderRemote에 parent_id 2-pass 적용 + upsertLinkRemote 예외 가드
```

### 테스트/분석 현황

- `fvm flutter analyze`: 에러/경고 0. 린트 info는 모두 pre-existing.
- `fvm flutter test`: **217 passed, 2 skipped, 1 pre-existing failure** (`test/util/url_loader_test.dart` — 실네트워크 `zdnet.co.kr` 호출이라 이번 작업 무관, 이 브랜치 밖에서도 실패함)

---

## 5. 코드베이스 스냅샷 (실제 `file:line`)

### 신규 파일

- `lib/cubits/folders/create_folder_result.dart` — sealed `CreateFolderResult` + `Created`/`DuplicateSibling`/`ParentMissing`/`CreateFolderFailed`
- `lib/provider/local/folder_exceptions.dart` — `FolderException` 추상 + 4 subclasses (`SiblingNameTakenException`, `ParentNotFoundException`, `ParentNotClassifiedException`, `UnclassifiedCreationException`)
- `lib/ui/widget/folder/show_create_folder_sheet.dart` (343 lines) — 신규 시트
- `test/provider/sync/sync_repository_upsert_test.dart` — Task 1 테스트
- `test/ui/widget/folder/show_create_folder_sheet_test.dart` + `.mocks.dart` — Task 4 위젯 테스트 (9 passed)

### 수정된 파일 및 위치

- `lib/provider/sync/sync_repository.dart` (522 lines)
  - `@visibleForTesting resolveRemoteFolderIdForTest` hook 필드
  - `_resolveFolderOrTestHook(userId, localId)` private helper
  - `upsertFolderRemote` — 2-pass 패턴, `parent_id: null` 하드코드 제거
  - `upsertLinkRemote` — `_resolveRemoteFolderId` 예외 try/catch 추가

- `lib/provider/local/local_folder_repository.dart` (356 lines)
  - `createFolder` (lines 73-104) — 부모 존재 가드, 형제 이름 방어선, typed `FolderException` 계열 throw
  - `isSiblingNameTaken(int? parentId, String name)` (line 116~) — 루트/중첩 범위 검사, `AND is_classified = 1`로 미분류 폴더 매칭 제외

- `lib/cubits/folders/local_folders_cubit.dart` (170 lines)
  - `createFolder(String name, {int? parentId}) → Future<CreateFolderResult>` — `SiblingNameTakenException → DuplicateSibling`, `ParentNotFoundException`/`ParentNotClassifiedException → ParentMissing`, 그 외 → `CreateFolderFailed(e)`

- `lib/ui/view/links/my_link_view.dart` (850 lines)
  - `buildChildFoldersSection(context, folders, state, currentFolder)` (line 445~) — 미분류 숨김 + 빈 상태 "하위 폴더 없음"
  - `_buildChildFoldersHeader` (line 543~) — `+` 아이콘 포함 헤더
  - `_onAddChildFolder(context, parent)` (line 581~) — 시트 열기 + 토스트 + 리프레시. 부모에 머무름
  - 호출부 line 191: `buildChildFoldersSection(context, folders, state, folder)`

- `lib/ui/page/my_folder/my_folder_page.dart`
  - line 179~ `onTap`: `showCreateFolderSheet(context)` → mounted 가드 → 토스트 먼저 → `moveToMyLinksView` (순서 중요)

- `lib/ui/widget/add_folder/folder_add_title.dart`
  - line 31: `showCreateFolderSheet(context, allowParentPick: false)` — 공유/업로드 플로우 루트 고정
  - 시그니처에 `moveToMyLinksView` 옵셔널 추가됨(기존 3개 caller는 전달 안 해서 영향 없음)

- `lib/ui/widget/dialog/bottom_dialog.dart`
  - `showFolderOptionsDialog`의 Column 첫 번째 child로 `BottomListItem('하위 폴더 추가', …)` 추가 (line 383~)
  - callback은 `Navigator.pop(context)` → `await showCreateFolderSheet(parentContext, initialParentId: currFolder.id)` → mounted 가드 → 토스트 → cubit refresh (fromLinkView일 때 link cubit도)
  - `saveEmptyFolder`, `runCallback` 제거
  - `FolderNameCubit` import 제거 (이 파일에서만 쓰였음)

### 삭제된 파일

- `lib/ui/widget/add_folder/show_add_folder_dialog.dart`

### 유지된 파일 (삭제하지 말 것)

- `lib/cubits/folders/folder_name_cubit.dart` — `show_rename_folder_dialog.dart`가 사용 중

### 시트 공개 API (`show_create_folder_sheet.dart`)

```dart
/// 루트 또는 특정 부모 아래에 새 폴더를 만드는 바텀 시트.
/// 취소=null, 생성 성공=새 폴더 id 반환.
Future<int?> showCreateFolderSheet(
  BuildContext context, {
  int? initialParentId,        // 기본 부모 (null=루트)
  bool allowParentPick = true, // false면 상위 폴더 행 숨김 + 고정
});
```

내부 특징:
- 호출부 context에서 `LocalFoldersCubit`을 **미리 캡처**한 뒤 `BlocProvider.value`로 시트 내부에 재주입. `showModalBottomSheet`가 시트 빌더를 `Overlay` 위에서 열어 InheritedWidget 루트가 바뀌기 때문에 이 우회가 필요. `BlocProvider.value`라 시트가 cubit을 close하지 않음.
- Dart 3 sealed class exhaustive switch로 `CreateFolderResult` 4개 분기 처리.
- 상위 폴더 행은 `showPickFolderSheet(includeUnclassified: false)` 호출.
- `maxLength: 20`, `autofocus: true`, UnderlineInputBorder + `primary800` focus.

---

## 6. 결정 이력 요약

스펙 브레인스토밍 단계에서 확정된 모든 정책:

| 결정 | 값 | 근거 |
|---|---|---|
| 대상 플랫폼 | 앱 + Chrome 확장, **앱 먼저** | Q1 |
| 앱 생성 진입점 | **3개**: MyLinkView 하위 폴더 섹션 `+` / `...` 옵션 "하위 폴더 추가" / 내 폴더 루트 "+"  | Q2 |
| 공유/업로드 플로우 | **루트 고정** (`allowParentPick: false`) | Q2 |
| 깊이 제한 | **무제한**. 자기-후손 이동 금지만 유지 | Q3 |
| 이름 중복 범위 | **형제 범위만** 금지. 경로 다르면 동명 허용. 대소문자/유니코드 정규화 안 함 (바이트-equal) | Q4 |
| Pro 동기화 수정 | `upsertFolderRemote`를 **2-pass** 패턴으로 (링크 업서트와 동일 패턴). 부모 미해결 시 `dirty=true` + 조기 반환 | Q6 |
| 구 다이얼로그 개조 수위 | **전면 교체 (옵션 C)**. `showAddFolderDialog` 폐기, `showCreateFolderSheet` 신규 | 사용자 지시 |
| ParentRow 위치 | TextField **위** | Q-A1 |
| 빈 "하위 폴더" 섹션 | 헤더 유지 + "하위 폴더 없음" 문구 + `+` 노출 | Q-B1 |
| 시트 제목 | 루트/중첩 공통 **"새로운 폴더"** | Q-C1 |
| 예외 모델 | **타입 있는 `FolderException` 계열** (Task 3 code review 후 도입) — `StateError` 문자열 매칭 제거 | 리뷰 피드백 |
| `folder_name_cubit.dart` | **이번 스펙에서 삭제 안 함**. rename 다이얼로그가 계속 사용 중 | 구현 중 발견 |

---

## 7. 열린 질문

현재 **모든 정책 확정됨**. 남은 것은 구현 작업 (Task 8, 9)과 Phase 2 착수 시점 결정뿐.

- Phase 2(Chrome 확장) 시작 시 재확정할 것들은 스펙 문서 "Phase 2 — 확장 초안" 섹션에 나열되어 있음 (모달 vs 인라인 input, 형제 중복 검사 위치, 북마크 동기화 상호작용 등).

---

## 8. 작업 재개 기술 가이드

### 세션 초기 체크

```bash
cd /Users/kangmin/dev/ac_project_app
git branch --show-current   # feat/nested-folder-create 기대
git log --oneline develop..HEAD | wc -l   # 13 기대
git stash list   # stash@{0} "pre-nested-folder-work" 한 줄 기대
```

### 빠른 재확인 명령

```bash
# 전체 테스트 (url_loader_test 네트워크 실패 1건은 무시)
fvm flutter test

# 정적 분석
fvm flutter analyze

# 중첩 폴더 관련 테스트만
fvm flutter test test/provider/local/local_folder_repository_test.dart \
                  test/cubits/local_folders_cubit_test.dart \
                  test/provider/sync/sync_repository_upsert_test.dart \
                  test/ui/widget/folder/show_create_folder_sheet_test.dart
```

### 시뮬레이터로 스모크 확인

```bash
fvm flutter run -d <device_id>
# 확인 체크:
# 1) 내 폴더 탭 "+ 새 폴더" → 시트 → 루트 생성 → 자동 네비 + 토스트
# 2) 분류된 폴더 상세 → "하위 폴더 (0)" + "하위 폴더 없음" + "+" 버튼 노출
# 3) "+" 버튼 → 시트 → 이름 입력 → 생성 → 부모에 머무름 + 토스트
# 4) 우상단 "..." → "하위 폴더 추가" 최상단 노출 → 동일 시트 흐름
# 5) 공유 메뉴에서 링크 공유 → "+ 새 폴더" → 루트 고정 생성
# 6) 미분류 폴더 상세 → "하위 폴더" 섹션 전체 숨김
```

### stash 복구 (세션 시작 전 변경사항)

```bash
# 현재 stash 내용 확인
git stash show -p stash@{0}   # ios pbxproj 변경사항
# 복구하려면 (선택)
git stash pop stash@{0}
```

### PR 생성 (Task 8, 9 완료 후)

```bash
git push -u origin feat/nested-folder-create
gh pr create --base develop --title "feat(folder): 중첩 폴더 생성 기능 (Phase 1)" --body "$(cat <<'EOF'
## Summary
- 앱에 "특정 폴더 아래에 새 폴더 만들기" 쓰기 경로 추가 (진입점 3개)
- Pro 동기화 `upsertFolderRemote`의 숨은 `parent_id` 유실 버그 수정 (2-pass 패턴)
- 구 `showAddFolderDialog` 폐기, `showCreateFolderSheet`로 전면 교체
- 공유/업로드 플로우는 루트 고정(`allowParentPick: false`)으로 기존 동작 유지

## 스펙 & 계획
- docs/superpowers/specs/2026-04-23-nested-folder-create-design.md
- docs/superpowers/plans/2026-04-23-nested-folder-create-plan.md

## 테스트
- 단위/위젯 테스트 전부 통과 (Task 1~7 자동)
- E2E 골든 플로우 (Task 8) 로컬 PASS
- Pro 수동 검증 체크리스트 (Task 9) 완료 — 캡처 첨부

## 스코프 외
- Phase 2 (Chrome 확장) — 별도 스펙/PR로 후속
- `folder_name_cubit.dart` 완전 폐기 — rename 다이얼로그 리팩터 필요, 후속
EOF
)"
```

---

## 9. 후속 작업 메모 (이번 스펙 범위 외)

1. **`folder_name_cubit.dart` 완전 폐기** — rename 다이얼로그도 `showCreateFolderSheet`와 유사한 dumb 시트 패턴으로 리팩터하면 `FolderNameCubit`/`ButtonStateCubit` 모두 폐기 가능.
2. **Phase 2 — Chrome 확장** — 저장소 `/Users/kangmin/dev/linkpool-chrome-extension`. `storage.createFolder(name, parentId, bookmarkId)`는 이미 parentId 수용. 트리에 생성 UI만 없음.
3. **`pick_folder_sheet` 실시간 구조 반영** — 현재 스냅샷 기반. 로드 중 원격 머지로 구조 바뀌면 반영 안 됨. 필요시 별도 스펙.
4. **`backupToRemote` 대규모 폴더 최적화** — 수백 개 이상 폴더에서만 문제. 실사용 희박.

---

## 문서 자체 검증 체크리스트

새 세션이 이 문서만 읽고 Task 8·9를 진행할 때 막힐 포인트가 있는지:

- [x] 브랜치/stash 상태 Quick Resume에 명시
- [x] Task 8 진행 전 확인 목록 + 실제 key 이름 + 실행 명령 포함
- [x] Task 9 체크리스트 원본 그대로 + Supabase Studio 접근 전제 명시
- [x] 완료된 모든 파일의 실제 line 기반 위치 기록 (추정 없음)
- [x] 시트 공개 API 시그니처를 코드 그대로 포함
- [x] 결정 이력과 열린 질문 섹션 분리
- [x] PR 본문 템플릿 포함 (재개 시 복사만 하면 되게)

막히면 이 문서 섹션 5의 `file:line`을 먼저 열고, 그래도 모호하면 설계 스펙 / 구현 계획 문서로 drill-down.
