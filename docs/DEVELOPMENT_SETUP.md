# 개발 환경 설정 가이드

링크풀 앱 개발을 위한 환경 설정 가이드입니다.

## 목차

1. [필수 요구사항](#필수-요구사항)
2. [Flutter 설치](#flutter-설치)
3. [FVM 설정](#fvm-설정)
4. [프로젝트 설정](#프로젝트-설정)
5. [IDE 설정](#ide-설정)
6. [환경 변수 설정](#환경-변수-설정)
7. [Firebase 설정](#firebase-설정)
8. [문제 해결](#문제-해결)

---

## 필수 요구사항

| 도구 | 버전 | 설명 |
|------|------|------|
| Flutter | 3.24.5 | FVM으로 관리 |
| Dart | >= 3.5.0 | Flutter에 포함 |
| FVM | 최신 | Flutter 버전 관리 |
| Xcode | 15.0+ | iOS 개발 (macOS) |
| Android Studio | 최신 | Android 개발 |
| Git | 최신 | 버전 관리 |

### 플랫폼별 요구사항

#### Android
- SDK: 24 ~ 33
- Gradle: 7.4

#### iOS
- Minimum Deployments: iOS 15.0
- Xcode 15.0 이상

---

## Flutter 설치

### macOS

```bash
# Homebrew로 Flutter 설치 (권장하지 않음 - FVM 사용)
# 아래 FVM 설정 참조
```

### Windows

1. [Flutter 공식 사이트](https://flutter.dev/docs/get-started/install/windows)에서 다운로드
2. 환경 변수에 Flutter bin 경로 추가

---

## FVM 설정

FVM(Flutter Version Management)을 사용하여 프로젝트 Flutter 버전을 관리합니다.

### FVM 설치

```bash
# Homebrew (macOS)
brew tap leoafarias/fvm
brew install fvm

# 또는 pub global
dart pub global activate fvm
```

### 프로젝트 Flutter 버전 설정

```bash
# 프로젝트 디렉토리에서
cd ac_project_app

# 프로젝트에 지정된 Flutter 버전 설치
fvm install

# 또는 특정 버전 설치
fvm install 3.24.5

# 프로젝트에 버전 적용
fvm use 3.24.5
```

### FVM 사용법

```bash
# Flutter 명령어 실행
fvm flutter pub get
fvm flutter run
fvm flutter build apk

# 설치된 버전 목록
fvm list

# 프로젝트 버전 확인
fvm flutter --version
```

---

## 프로젝트 설정

### 1. 저장소 클론

```bash
git clone https://github.com/Monday-Rocket/ac_project_app.git
cd ac_project_app
```

### 2. FVM 설정

```bash
# .fvmrc에 지정된 Flutter 버전 설치
fvm install
```

### 3. 의존성 설치

```bash
fvm flutter pub get
```

### 4. 코드 생성

프로젝트에서 사용하는 코드 생성 도구를 실행합니다:

```bash
# build_runner (freezed, json_serializable 등)
fvm dart run build_runner build --delete-conflicting-outputs

# flutter_gen (assets 생성)
fvm dart run flutter_gen -c pubspec.yaml

# 또는 Makefile 사용
make gen
```

### 5. 앱 실행

```bash
# 디버그 모드
fvm flutter run

# 특정 기기 지정
fvm flutter devices  # 기기 목록 확인
fvm flutter run -d <device_id>
```

---

## IDE 설정

### VS Code

#### 필수 확장 프로그램

- Flutter
- Dart
- Bloc

#### settings.json 설정

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  }
}
```

### Android Studio / IntelliJ IDEA

1. **File > Project Structure > SDKs**
   - Flutter SDK 경로: `<project>/.fvm/flutter_sdk`

2. **Preferences > Languages & Frameworks > Flutter**
   - Flutter SDK path: `<project>/.fvm/flutter_sdk`

3. **필수 플러그인**
   - Flutter
   - Dart
   - Bloc

---

## 환경 변수 설정

### .env 파일 설정

프로젝트 루트에 `.env` 파일을 생성합니다:

```bash
# .env 예시
BASE_URL=https://api.example.com
KAKAO_NATIVE_KEY=your_kakao_key
```

> **주의**: `.env` 파일은 `.gitignore`에 포함되어 있습니다. 팀원에게 별도로 공유받으세요.

---

## Firebase 설정

### Firebase 프로젝트 연동

1. Firebase Console에서 프로젝트 생성
2. iOS/Android 앱 추가
3. `google-services.json` (Android) 다운로드 → `android/app/` 에 배치
4. `GoogleService-Info.plist` (iOS) 다운로드 → `ios/Runner/` 에 배치

### firebase_options.dart

Firebase 설정 파일은 CI/CD에서 시크릿으로 관리됩니다. 로컬 개발 시 팀원에게 공유받으세요.

```bash
# 위치
lib/firebase_options.dart
```

---

## Makefile 명령어

개발 편의를 위한 Makefile 명령어:

```bash
# 전체 설정 (FVM 설치 + 의존성 + 코드 생성)
make setup

# 코드 생성만
make gen

# 테스트 실행
make test

# 커버리지 리포트
make test-coverage

# 린트 검사
make lint

# 코드 포맷팅
make lint-fix

# 커밋 전 검사
make precommit

# 빌드 파일 정리
make clean
```

---

## 문제 해결

### FVM 관련

**문제**: `fvm flutter` 명령어가 동작하지 않음
```bash
# FVM 재설치
brew uninstall fvm
brew install fvm

# 또는 캐시 정리
fvm flutter clean
fvm flutter pub get
```

### 빌드 관련

**문제**: 코드 생성 오류
```bash
# 생성 파일 삭제 후 재생성
fvm dart run build_runner clean
fvm dart run build_runner build --delete-conflicting-outputs
```

**문제**: Gradle 빌드 실패
```bash
# Android 캐시 정리
cd android
./gradlew clean
cd ..
fvm flutter clean
fvm flutter pub get
```

**문제**: iOS 빌드 실패
```bash
# CocoaPods 재설치
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
fvm flutter clean
fvm flutter pub get
```

### 의존성 관련

**문제**: pub get 실패
```bash
# pubspec.lock 삭제 후 재시도
rm pubspec.lock
fvm flutter pub get
```

---

## 다음 단계

- [아키텍처 가이드](ARCHITECTURE.md) - 프로젝트 구조 이해
- [테스트 가이드](TESTING_GUIDE.md) - 테스트 작성 방법
- [기여 가이드](../CONTRIBUTING.md) - 기여 방법
