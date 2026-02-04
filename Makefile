# 링크풀 (LinkPool) Makefile
# Flutter 개발을 위한 공통 명령어 모음

.PHONY: setup install gen test test-coverage lint lint-fix precommit clean build-android build-ios help

# 기본 타겟
.DEFAULT_GOAL := help

# FVM Flutter 명령어
FLUTTER := fvm flutter
DART := fvm dart

#---------------------------------------------------------------------------
# 설정 관련
#---------------------------------------------------------------------------

## FVM 설치 및 프로젝트 초기 설정
setup: install-fvm install gen
	@echo "✅ Setup completed!"

## FVM 설치 (Homebrew)
install-fvm:
	@echo "📦 Installing FVM..."
	@which fvm > /dev/null || brew tap leoafarias/fvm && brew install fvm
	@fvm install
	@echo "✅ FVM installed!"

## Flutter 의존성 설치
install:
	@echo "📦 Installing dependencies..."
	@$(FLUTTER) pub get
	@echo "✅ Dependencies installed!"

#---------------------------------------------------------------------------
# 코드 생성
#---------------------------------------------------------------------------

## 코드 생성 (build_runner + flutter_gen)
gen: gen-build gen-assets
	@echo "✅ Code generation completed!"

## build_runner 실행 (freezed, json_serializable)
gen-build:
	@echo "🔨 Running build_runner..."
	@$(DART) run build_runner build --delete-conflicting-outputs

## flutter_gen 실행 (assets)
gen-assets:
	@echo "🎨 Running flutter_gen..."
	@$(DART) run flutter_gen -c pubspec.yaml

## build_runner 감시 모드
gen-watch:
	@echo "👀 Watching for changes..."
	@$(DART) run build_runner watch --delete-conflicting-outputs

#---------------------------------------------------------------------------
# 테스트
#---------------------------------------------------------------------------

## 테스트 실행
test:
	@echo "🧪 Running tests..."
	@$(FLUTTER) test

## 커버리지 포함 테스트
test-coverage:
	@echo "🧪 Running tests with coverage..."
	@$(FLUTTER) test --coverage
	@echo "📊 Coverage report generated at coverage/lcov.info"

## 커버리지 HTML 리포트 생성
test-coverage-html: test-coverage
	@echo "📊 Generating HTML report..."
	@which genhtml > /dev/null || (echo "❌ lcov not found. Install with: brew install lcov" && exit 1)
	@genhtml coverage/lcov.info -o coverage/html
	@echo "✅ HTML report generated at coverage/html/index.html"
	@open coverage/html/index.html

## 특정 테스트 파일 실행 (usage: make test-file FILE=test/path/to/test.dart)
test-file:
	@echo "🧪 Running $(FILE)..."
	@$(FLUTTER) test $(FILE)

## 통합 테스트 실행
test-integration:
	@echo "🧪 Running integration tests..."
	@$(FLUTTER) test integration_test/

#---------------------------------------------------------------------------
# 린트 & 포맷팅
#---------------------------------------------------------------------------

## 린트 검사
lint:
	@echo "🔍 Running flutter analyze..."
	@$(FLUTTER) analyze

## 코드 포맷팅
lint-fix:
	@echo "🔧 Formatting code..."
	@$(DART) format .
	@$(DART) fix --apply
	@echo "✅ Code formatted!"

## 린트 오류 자동 수정
lint-auto:
	@echo "🔧 Auto-fixing lint issues..."
	@$(DART) fix --apply

#---------------------------------------------------------------------------
# 커밋 전 검사
#---------------------------------------------------------------------------

## 커밋 전 전체 검사 (lint + test)
precommit: lint test
	@echo "✅ Pre-commit checks passed!"

## 빠른 커밋 전 검사 (lint만)
precommit-quick: lint
	@echo "✅ Quick pre-commit check passed!"

#---------------------------------------------------------------------------
# 빌드
#---------------------------------------------------------------------------

## Android APK 빌드 (release)
build-android:
	@echo "🤖 Building Android APK..."
	@$(FLUTTER) build apk --release
	@echo "✅ APK built at build/app/outputs/flutter-apk/app-release.apk"

## Android App Bundle 빌드
build-android-bundle:
	@echo "🤖 Building Android App Bundle..."
	@$(FLUTTER) build appbundle --release
	@echo "✅ AAB built at build/app/outputs/bundle/release/app-release.aab"

## iOS 빌드
build-ios:
	@echo "🍎 Building iOS..."
	@$(FLUTTER) build ios --release --no-codesign
	@echo "✅ iOS build completed!"

## iOS IPA 빌드 (requires signing)
build-ios-ipa:
	@echo "🍎 Building iOS IPA..."
	@$(FLUTTER) build ipa
	@echo "✅ IPA built!"

#---------------------------------------------------------------------------
# 정리
#---------------------------------------------------------------------------

## 빌드 파일 정리
clean:
	@echo "🧹 Cleaning build files..."
	@$(FLUTTER) clean
	@echo "✅ Clean completed!"

## 완전 정리 (빌드 + 의존성)
clean-all: clean
	@echo "🧹 Removing pubspec.lock..."
	@rm -f pubspec.lock
	@echo "🧹 Removing generated files..."
	@find . -name "*.g.dart" -delete
	@find . -name "*.freezed.dart" -delete
	@echo "✅ Full clean completed!"

## iOS 정리 (CocoaPods)
clean-ios:
	@echo "🧹 Cleaning iOS..."
	@cd ios && rm -rf Pods Podfile.lock && pod install --repo-update
	@echo "✅ iOS clean completed!"

## Android 정리 (Gradle)
clean-android:
	@echo "🧹 Cleaning Android..."
	@cd android && ./gradlew clean
	@echo "✅ Android clean completed!"

#---------------------------------------------------------------------------
# 실행
#---------------------------------------------------------------------------

## 앱 실행 (debug)
run:
	@echo "🚀 Running app..."
	@$(FLUTTER) run

## 기기 목록 확인
devices:
	@$(FLUTTER) devices

## Flutter doctor
doctor:
	@$(FLUTTER) doctor -v

#---------------------------------------------------------------------------
# 도움말
#---------------------------------------------------------------------------

## 도움말 표시
help:
	@echo ""
	@echo "📱 링크풀 (LinkPool) - Flutter 개발 명령어"
	@echo "============================================"
	@echo ""
	@echo "사용법: make [target]"
	@echo ""
	@echo "🔧 설정:"
	@echo "  setup            FVM 설치 및 전체 프로젝트 설정"
	@echo "  install          Flutter 의존성 설치"
	@echo ""
	@echo "🔨 코드 생성:"
	@echo "  gen              코드 생성 (build_runner + flutter_gen)"
	@echo "  gen-build        build_runner만 실행"
	@echo "  gen-assets       flutter_gen만 실행"
	@echo "  gen-watch        build_runner 감시 모드"
	@echo ""
	@echo "🧪 테스트:"
	@echo "  test             테스트 실행"
	@echo "  test-coverage    커버리지 포함 테스트"
	@echo "  test-coverage-html  HTML 커버리지 리포트 생성"
	@echo "  test-integration 통합 테스트 실행"
	@echo ""
	@echo "🔍 린트:"
	@echo "  lint             린트 검사"
	@echo "  lint-fix         코드 포맷팅"
	@echo "  lint-auto        린트 오류 자동 수정"
	@echo ""
	@echo "✅ 커밋 전:"
	@echo "  precommit        전체 검사 (lint + test)"
	@echo "  precommit-quick  빠른 검사 (lint만)"
	@echo ""
	@echo "📦 빌드:"
	@echo "  build-android    Android APK 빌드"
	@echo "  build-android-bundle  Android App Bundle 빌드"
	@echo "  build-ios        iOS 빌드"
	@echo ""
	@echo "🧹 정리:"
	@echo "  clean            빌드 파일 정리"
	@echo "  clean-all        완전 정리"
	@echo "  clean-ios        iOS 정리 (CocoaPods)"
	@echo "  clean-android    Android 정리 (Gradle)"
	@echo ""
	@echo "🚀 실행:"
	@echo "  run              앱 실행"
	@echo "  devices          기기 목록"
	@echo "  doctor           Flutter doctor"
	@echo ""
