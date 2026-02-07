# 프로젝트 초기 설정

프로젝트 초기 환경을 설정합니다.

## 실행 단계

1. FVM으로 Flutter 버전 설치
2. 의존성 설치
3. 코드 생성

```bash
fvm install
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run flutter_gen -c pubspec.yaml
```

위 명령어들을 순서대로 실행해주세요.
