# 기여 가이드

링크풀 프로젝트에 기여해 주셔서 감사합니다! 이 문서는 프로젝트에 기여하는 방법을 안내합니다.

## 목차

1. [행동 강령](#행동-강령)
2. [개발 환경 설정](#개발-환경-설정)
3. [브랜치 전략](#브랜치-전략)
4. [커밋 규칙](#커밋-규칙)
5. [Pull Request 가이드](#pull-request-가이드)
6. [코드 스타일](#코드-스타일)
7. [테스트 가이드](#테스트-가이드)
8. [이슈 보고](#이슈-보고)

---

## 행동 강령

모든 기여자는 서로 존중하고 건설적인 피드백을 제공해야 합니다.

- 다양한 의견과 경험을 존중합니다
- 건설적인 비판을 수용합니다
- 커뮤니티에 가장 좋은 것에 집중합니다
- 다른 커뮤니티 구성원에게 공감을 보여줍니다

---

## 개발 환경 설정

자세한 설정 방법은 [개발 환경 설정 가이드](docs/DEVELOPMENT_SETUP.md)를 참조하세요.

### 빠른 시작

```bash
# 1. 저장소 Fork 및 Clone
git clone https://github.com/<your-username>/ac_project_app.git
cd ac_project_app

# 2. 업스트림 추가
git remote add upstream https://github.com/Monday-Rocket/ac_project_app.git

# 3. 환경 설정
make setup

# 4. 앱 실행
fvm flutter run
```

---

## 브랜치 전략

### 브랜치 구조

```
main (production)
  └── develop (개발)
        ├── feature/기능명
        ├── fix/버그명
        └── refactor/개선사항
```

### 브랜치 명명 규칙

| 타입 | 형식 | 예시 |
|------|------|------|
| 기능 | `feature/기능명` | `feature/share-folder` |
| 버그 수정 | `fix/버그명` | `fix/login-crash` |
| 리팩토링 | `refactor/개선사항` | `refactor/api-structure` |
| 문서 | `docs/문서명` | `docs/readme-update` |
| 테스트 | `test/테스트명` | `test/folder-api` |

### 브랜치 생성

```bash
# 최신 develop 브랜치에서 시작
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-name
```

---

## 커밋 규칙

### 커밋 메시지 형식

```
<타입>(<범위>): <제목>

<본문>

<꼬리말>
```

### 커밋 타입

| 타입 | 설명 |
|------|------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 수정 |
| `style` | 코드 포맷팅 (기능 변경 없음) |
| `refactor` | 코드 리팩토링 |
| `test` | 테스트 추가/수정 |
| `chore` | 빌드, 설정 파일 수정 |

### 예시

```
feat(folder): 폴더 공유 기능 추가

- 공유 링크 생성 API 연동
- 공유 설정 페이지 구현
- 공유 권한 관리 Cubit 추가

Closes #123
```

```
fix(login): 애플 로그인 크래시 수정

iOS 15에서 발생하는 애플 로그인 크래시 문제 해결
```

### 커밋 전 체크리스트

```bash
# 1. 린트 검사
make lint

# 2. 테스트 실행
make test

# 3. 또는 한 번에
make precommit
```

---

## Pull Request 가이드

### PR 생성 전

1. develop 브랜치와 동기화
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

2. 테스트 통과 확인
   ```bash
   make test
   ```

3. 린트 검사 통과
   ```bash
   make lint
   ```

### PR 템플릿

```markdown
## 변경 사항
- 변경 내용 1
- 변경 내용 2

## 관련 이슈
- Closes #이슈번호

## 테스트
- [ ] 단위 테스트 추가/수정
- [ ] 통합 테스트 확인
- [ ] 수동 테스트 완료

## 스크린샷 (UI 변경 시)
| Before | After |
|--------|-------|
| 이미지 | 이미지 |

## 체크리스트
- [ ] 코드 스타일 가이드 준수
- [ ] 테스트 통과
- [ ] 문서 업데이트 (필요시)
```

### PR 규칙

1. **작은 단위로 PR 생성**: 하나의 PR에 하나의 기능/수정
2. **명확한 제목**: 커밋 메시지 규칙과 동일
3. **상세한 설명**: 변경 사항과 이유 명시
4. **리뷰어 지정**: 최소 1명 이상의 리뷰어
5. **CI 통과**: 모든 CI 검사 통과 필수

---

## 코드 스타일

### Dart/Flutter 스타일 가이드

프로젝트는 [very_good_analysis](https://pub.dev/packages/very_good_analysis) 린트 규칙을 따릅니다.

### 기본 규칙

```dart
// DO: 명확한 변수명 사용
final List<Folder> myFolders = [];

// DON'T: 축약형 변수명
final List<Folder> f = [];

// DO: const 사용 가능한 경우 const 사용
const EdgeInsets.all(16);

// DO: trailing comma 사용
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Text('Hello'),  // trailing comma
  );
}
```

### 파일 구조

```dart
// 1. imports (dart → package → relative)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/folder.dart';

// 2. part 선언
part 'folder.freezed.dart';

// 3. 상수/typedef
const int maxFolders = 100;

// 4. 클래스
class FolderWidget extends StatelessWidget {
  // ...
}
```

### 포맷팅

```bash
# 자동 포맷팅
make lint-fix

# 또는 직접 실행
fvm flutter format .
```

---

## 테스트 가이드

자세한 테스트 가이드는 [테스트 가이드](docs/TESTING_GUIDE.md)를 참조하세요.

### 테스트 필수 사항

1. **새 기능**: 단위 테스트 필수
2. **버그 수정**: 회귀 테스트 추가
3. **API 변경**: API 테스트 업데이트

### 테스트 실행

```bash
# 전체 테스트
make test

# 커버리지 포함
make test-coverage

# 특정 테스트
fvm flutter test test/provider/api/folders/folder_api_test.dart
```

### 커버리지 목표

- 전체: 10% 이상 (점진적 증가 목표)
- 신규 코드: 80% 이상

---

## 이슈 보고

### 버그 리포트

```markdown
## 버그 설명
명확하고 간결한 버그 설명

## 재현 방법
1. '...'로 이동
2. '...' 클릭
3. '...'까지 스크롤
4. 오류 확인

## 예상 동작
예상했던 동작 설명

## 스크린샷
해당되는 경우 스크린샷 첨부

## 환경
- OS: [예: iOS 15.0]
- 앱 버전: [예: 1.0.73]
- 기기: [예: iPhone 14]
```

### 기능 요청

```markdown
## 기능 설명
제안하는 기능에 대한 명확하고 간결한 설명

## 문제점
이 기능이 해결하는 문제 설명

## 대안
고려한 대안 솔루션이나 기능

## 추가 정보
기능 요청에 대한 다른 컨텍스트나 스크린샷
```

---

## 도움이 필요하신가요?

- [개발 환경 설정](docs/DEVELOPMENT_SETUP.md)
- [아키텍처 가이드](docs/ARCHITECTURE.md)
- [테스트 가이드](docs/TESTING_GUIDE.md)

문의사항이 있으시면 이슈를 생성해 주세요!
