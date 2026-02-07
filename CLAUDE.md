# 링크풀 (LinkPool) - Claude Code 프로젝트 가이드

## 프로젝트 개요

링크풀은 링크를 체계적으로 관리하는 Flutter 모바일 앱입니다.

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
├── di/         # 의존성 주입
├── models/     # 데이터 모델
├── provider/   # API, 데이터 제공자
├── ui/         # UI (page, view, widget)
└── util/       # 유틸리티

test/
├── provider/api/  # API 테스트
├── ui/            # 위젯 테스트
└── util/          # 유틸리티 테스트
```

## 개발 규칙

### 상태 관리
- flutter_bloc의 **Cubit** 패턴 사용
- State는 별도 파일로 분리 (`*_state.dart`)

### 의존성 주입
- `lib/di/set_up_get_it.dart`에서 등록
- `getIt<T>()`로 주입받아 사용

### 테스트
- API: MockClient 사용
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

  final ExampleApi api = getIt();

  Future<void> fetchData() async {
    emit(ExampleLoadingState());
    (await api.getData()).when(
      success: (data) => emit(ExampleLoadedState(data)),
      error: (msg) => emit(ExampleErrorState(msg)),
    );
  }
}
```

### API 테스트 작성
```dart
test('getData success', () async {
  final mockClient = getMockClient(expected, '/endpoint');
  final api = ExampleApi(CustomClient(client: mockClient));

  final result = await api.getData();

  result.when(
    success: (data) => expect(data, expected),
    error: fail,
  );
});
```

## 참고 문서

- [개발 환경 설정](docs/DEVELOPMENT_SETUP.md)
- [아키텍처](docs/ARCHITECTURE.md)
- [테스트 가이드](docs/TESTING_GUIDE.md)
- [기여 가이드](CONTRIBUTING.md)
- [작업목록](작업목록.md)
