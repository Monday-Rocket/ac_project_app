# 테스트 가이드

링크풀 앱의 테스트 전략 및 작성 가이드입니다.

## 목차

1. [개요](#개요)
2. [테스트 구조](#테스트-구조)
3. [단위 테스트](#단위-테스트)
4. [Cubit 테스트](#cubit-테스트)
5. [위젯 테스트](#위젯-테스트)
6. [통합 테스트](#통합-테스트)
7. [테스트 실행](#테스트-실행)
8. [커버리지](#커버리지)
9. [Best Practices](#best-practices)

---

## 개요

### 테스트 원칙

1. **TDD (Test-Driven Development)**: 테스트 먼저 작성
2. **격리된 테스트**: 각 테스트는 독립적으로 실행
3. **명확한 테스트명**: 테스트 목적이 드러나는 이름
4. **Mock 활용**: 외부 의존성 격리

### 테스트 피라미드

```
        /\
       /  \     E2E Tests (적은 수)
      /----\
     /      \   Integration Tests
    /--------\
   /          \ Unit Tests (많은 수)
  /------------\
```

### 사용 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| `flutter_test` | Flutter 테스트 프레임워크 |
| `bloc_test` | Cubit/Bloc 테스트 |
| `mockito` | Mock 객체 생성 |
| `sqflite_common_ffi` | SQLite 테스트용 FFI |

---

## 테스트 구조

### 디렉토리 구조

```
test/
├── provider/
│   └── local/
│       ├── local_folder_repository_test.dart
│       ├── local_link_repository_test.dart
│       └── local_bulk_repository_test.dart
├── ui/
│   ├── widget/
│   │   └── widget_offset_test.dart
│   └── widget_tap_helper.dart
├── util/
│   ├── date_utils_test.dart
│   ├── number_commas_test.dart
│   ├── string_utils_test.dart
│   ├── url_loader_test.dart
│   └── url_valid_test.dart
├── coverage_test.dart
└── test_strings.dart
```

### 파일 명명 규칙

- 테스트 파일: `*_test.dart`
- Mock 파일: `mock_*.dart`
- Helper 파일: `*_helper.dart`

---

## 단위 테스트

### 유틸리티 함수 테스트

```dart
// test/util/url_valid_test.dart
import 'package:ac_project_app/util/url_valid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('URL Validation Tests', () {
    test('valid URL should return true', () {
      expect(isValidUrl('https://example.com'), true);
      expect(isValidUrl('http://example.com/path'), true);
    });

    test('invalid URL should return false', () {
      expect(isValidUrl('not a url'), false);
      expect(isValidUrl(''), false);
    });
  });
}
```

### 날짜 유틸 테스트

```dart
// test/util/date_utils_test.dart
import 'package:ac_project_app/util/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date Utils Tests', () {
    test('formatDate should format correctly', () {
      final date = DateTime(2023, 5, 15);
      expect(formatDate(date), '2023-05-15');
    });
  });
}
```

---

## Cubit 테스트

### bloc_test 사용

```dart
// test/cubits/folders/local_folders_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockLocalFolderRepository extends Mock implements LocalFolderRepository {}

void main() {
  group('LocalFoldersCubit Tests', () {
    late MockLocalFolderRepository mockRepository;

    setUp(() {
      mockRepository = MockLocalFolderRepository();
    });

    blocTest<LocalFoldersCubit, FoldersState>(
      'emits [Loading, Loaded] when getFolders succeeds',
      build: () {
        when(mockRepository.getAllFolders()).thenAnswer(
          (_) async => [
            const LocalFolder(id: 1, name: 'Test'),
          ],
        );
        return LocalFoldersCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.getFolders(),
      expect: () => [
        isA<FolderLoadingState>(),
        isA<FolderLoadedState>(),
      ],
    );

    blocTest<LocalFoldersCubit, FoldersState>(
      'emits [Loading, Error] when getFolders fails',
      build: () {
        when(mockRepository.getAllFolders()).thenThrow(
          Exception('Database error'),
        );
        return LocalFoldersCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.getFolders(),
      expect: () => [
        isA<FolderLoadingState>(),
        isA<FolderErrorState>(),
      ],
    );
  });
}
```

---

## 위젯 테스트

### 기본 위젯 테스트

```dart
// test/ui/widget/loading_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Loading Widget Tests', () {
    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

### BLoC 위젯 테스트

```dart
// test/ui/page/folder_page_test.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FolderPage Tests', () {
    late MockGetFoldersCubit mockCubit;

    setUp(() {
      mockCubit = MockGetFoldersCubit();
    });

    testWidgets('should show loading when state is loading', (tester) async {
      when(() => mockCubit.state).thenReturn(FolderLoadingState());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GetFoldersCubit>.value(
            value: mockCubit,
            child: const FolderPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show folders when state is loaded', (tester) async {
      when(() => mockCubit.state).thenReturn(
        FolderLoadedState([const Folder(id: 1, name: 'Test')], '1', 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GetFoldersCubit>.value(
            value: mockCubit,
            child: const FolderPage(),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
```

---

## 통합 테스트

### 설정

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('folder creation flow', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 폴더 추가 버튼 찾기
      final addButton = find.byKey(const Key('add_folder_button'));
      expect(addButton, findsOneWidget);

      // 폴더 추가 버튼 탭
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 폴더 생성 다이얼로그 확인
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
```

### 실행

```bash
fvm flutter test integration_test/
```

---

## 테스트 실행

### 전체 테스트

```bash
# Makefile 사용
make test

# 직접 실행
fvm flutter test
```

### 특정 파일 테스트

```bash
fvm flutter test test/provider/local/local_folder_repository_test.dart
```

### 특정 그룹/테스트

```bash
# 특정 테스트만
fvm flutter test --name "getMyFolders should return folder list"

# 특정 그룹만
fvm flutter test --name "LocalFolderRepository Tests"
```

### 상세 출력

```bash
fvm flutter test --reporter expanded
```

---

## 커버리지

### 커버리지 생성

```bash
# Makefile 사용
make test-coverage

# 직접 실행
fvm flutter test --coverage
```

### HTML 리포트 생성

```bash
# lcov 설치 (macOS)
brew install lcov

# HTML 리포트 생성
genhtml coverage/lcov.info -o coverage/html

# 브라우저에서 열기
open coverage/html/index.html
```

### 커버리지 목표

| 항목 | 현재 | 목표 |
|------|------|------|
| 전체 | TBD | 10%+ |
| 신규 코드 | - | 80%+ |
| Repository | - | 90%+ |
| Cubit | - | 80%+ |

### CI에서 커버리지

GitHub Actions에서 Codecov를 통해 커버리지를 추적합니다.

```yaml
# .github/workflows/code_coverage.yml
- name: Upload coverage reports to Codecov
  uses: codecov/codecov-action@v3
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    fail_ci_if_error: true
```

---

## Best Practices

### 1. 테스트 이름 작성

```dart
// GOOD: 명확한 테스트 이름
test('getAllFolders returns empty list when no folders exist', () {});

// BAD: 모호한 테스트 이름
test('test1', () {});
```

### 2. AAA 패턴

```dart
test('should return folder list', () {
  // Arrange (준비)
  final repo = LocalFolderRepository(databaseHelper: testDb);

  // Act (실행)
  final result = await repo.getAllFolders();

  // Assert (검증)
  expect(result, isEmpty);
});
```

### 3. 한 테스트에 하나의 검증

```dart
// GOOD
test('folder name should not be null', () {
  expect(folder.name, isNotNull);
});

test('folder name should be "Test"', () {
  expect(folder.name, 'Test');
});

// BAD (여러 검증)
test('folder validation', () {
  expect(folder.name, isNotNull);
  expect(folder.name, 'Test');
  expect(folder.id, 1);
});
```

### 4. setUp/tearDown 활용

```dart
void main() {
  late MockLocalFolderRepository mockRepo;

  setUp(() {
    mockRepo = MockLocalFolderRepository();
  });

  tearDown(() {
    // 정리 작업
  });
}
```

### 5. 테스트 데이터 분리

```dart
// test/test_strings.dart
const getNewLinksKey = 'links';
const getNewLinksValue = [...];

// 테스트에서 사용
import 'test_strings.dart';

test('bulk save', () {
  // getNewLinksKey, getNewLinksValue 사용
});
```

---

## 관련 문서

- [개발 환경 설정](DEVELOPMENT_SETUP.md)
- [아키텍처 가이드](ARCHITECTURE.md)
- [기여 가이드](../CONTRIBUTING.md)
