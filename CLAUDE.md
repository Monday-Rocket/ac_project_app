# 링크풀 (LinkPool) - Claude Code 프로젝트 가이드

## 프로젝트 개요

링크풀은 링크를 체계적으로 관리하는 **오프라인 전용** Flutter 모바일 앱입니다.

| 항목 | 내용 |
|------|------|
| 플랫폼 | iOS / Android |
| Flutter | 3.38.6 (FVM) |
| 상태관리 | flutter_bloc (Cubit) |
| DI | get_it |
| 테스트 | flutter_test, bloc_test, mockito |

## 주요 디렉토리

```
lib/
├── cubits/     # 상태 관리 (Cubit)
│   ├── common/ # 공통 Cubit (ButtonStateCubit 등)
│   ├── folders/ # 폴더 관련
│   ├── links/  # 링크 관련
│   └── ...
├── di/         # 의존성 주입
├── models/     # 데이터 모델
│   ├── local/  # 로컬 DB 모델
│   └── ...
├── provider/   # 데이터 제공자
│   ├── local/  # 로컬 DB (SQLite)
│   ├── kakao/  # 카카오 공유
│   └── ...
├── ui/         # UI (page, view, widget)
└── util/       # 유틸리티

test/
├── provider/local/ # 로컬 DB 테스트
├── ui/             # 위젯 테스트
└── util/           # 유틸리티 테스트
```

## 개발 규칙

### 상태 관리
- flutter_bloc의 **Cubit** 패턴 사용
- State는 별도 파일로 분리 (`*_state.dart`)

### 의존성 주입
- `lib/di/set_up_get_it.dart`에서 등록
- `getIt<T>()`로 주입받아 사용
- 로컬 DB Repository만 등록 (API 없음)

### 테스트
- 로컬 DB: sqflite 테스트
- Cubit: bloc_test 사용
- TDD 방식 권장

## 자주 쓰는 명령어

```bash
# 의존성 설치
fvm flutter pub get

# 코드 생성
fvm dart run build_runner build --delete-conflicting-outputs

# 테스트
fvm flutter test

# 린트
fvm flutter analyze

# 포맷팅
fvm dart format .
```

## 커스텀 명령어 (/project)

| 명령어 | 설명 |
|--------|------|
| `/project:setup` | 프로젝트 초기 설정 |
| `/project:gen` | 코드 생성 |
| `/project:test` | 테스트 실행 |
| `/project:lint` | 린트 검사 |
| `/project:precommit` | 커밋 전 검사 |
| `/project:dev-agent` | TDD 개발 에이전트 |
| `/project:test-agent` | 테스트 에이전트 |
| `/project:review-agent` | 코드 리뷰 에이전트 |

## 코드 패턴

### Cubit 작성
```dart
class ExampleCubit extends Cubit<ExampleState> {
  ExampleCubit() : super(ExampleInitialState());

  final LocalFolderRepository repo = getIt();

  Future<void> fetchData() async {
    emit(ExampleLoadingState());
    final data = await repo.getAllFolders();
    emit(ExampleLoadedState(data));
  }
}
```

## 운영 DB 직접 접속 (Supabase)

Pro/Free 전환, 테스트 데이터 정리, 원격 상태 검증 같은 작업에서 Supabase DB 에 직접 SQL 을 날려야 할 때가 있다. 접속 정보는 **프로젝트 루트 `.env`** 에 있음 (gitignored). Claude 는 쉘에서 다음 순서로 접근:

```bash
# 1) .env 로드 (프로젝트 루트에서 실행)
set -a && source .env && set +a

# 2) psql 호출 — psql 은 PATH 에 없으므로 절대경로 사용
/opt/homebrew/opt/libpq/bin/psql "$LINKPOOL_SUPABASE_DB_URL" -c "SELECT 1;"
```

원라이너 예시:
```bash
set -a && source .env && set +a && /opt/homebrew/opt/libpq/bin/psql "$LINKPOOL_SUPABASE_DB_URL" -c "SELECT id, email, plan, plan_expires_at FROM profiles WHERE email = 'linkpooltest2@gmail.com';"
```

**환경변수 이름** (양 프로젝트 공통):
- `LINKPOOL_SUPABASE_DB_URL` — psql 에 바로 넘기는 전체 connection string (pooler 경유, sslmode=require 포함)
- `LINKPOOL_SUPABASE_DB_PASSWORD` — 비밀번호만 (별도 도구가 URL 분해를 요구할 때)

**프로젝트 / 주요 테이블**:
- Supabase project ref: `gystdpdelnfblgyeckth`
- 테스트 계정: `linkpooltest2@gmail.com` (UUID `355d0598-e5e0-4ece-bb14-1dd03ec8e344`)
- 핵심 테이블: `profiles` (plan), `folders`, `links`, `auth.users`
- 스키마 정의: `linkpool-chrome-extension/supabase/migrations/*.sql` (앱과 공유)

**운영 규칙** — 이건 프로덕션 DB 이므로 다음 순서를 반드시 지킨다:
1. 먼저 `SELECT` 로 대상 row 를 확인해 사용자에게 보여준다.
2. `UPDATE`/`DELETE`/`INSERT` 같은 destructive 쿼리는 **사용자 명시 승인 후에만** 실행.
3. `RETURNING` 절을 가능한 한 포함해 변경된 내용을 즉시 확인 가능하게 한다.
4. 여러 유저에 걸친 대규모 변경은 원칙적으로 트랜잭션(`BEGIN; ... COMMIT;`)으로 감싼다.

## 참고 문서

- [동기화 모델 v2 (2026-04-23)](docs/SYNC_MODEL_V2.md)
- [개발 환경 설정](docs/DEVELOPMENT_SETUP.md)
- [아키텍처](docs/ARCHITECTURE.md)
- [테스트 가이드](docs/TESTING_GUIDE.md)
- [기여 가이드](CONTRIBUTING.md)
- [작업목록](작업목록.md)

# currentDate
Today's date is 2026-02-17.
