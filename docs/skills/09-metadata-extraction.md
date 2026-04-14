---
name: app-metadata-extraction
description: Flutter 앱 URL 메타데이터 추출 — OG 태그 파싱, URL 검증, User-Agent 스푸핑
type: feature
project: ac_project_app
tier: core
---

# 메타데이터 추출 (Metadata Extraction)

## 개요
URL에서 OpenGraph 메타데이터(제목, 이미지, 설명)를 자동 추출. 봇 감지 우회용 User-Agent 설정.

## 주요 파일
- `lib/util/url_loader.dart` — 메타데이터 로딩 (`loadData`, `isValidateUrl`)
- `lib/util/url_valid.dart` — HTTP GET으로 URL 접근성 확인 (`isValidUrl`)

## 핵심 함수
```dart
// url_loader.dart
UrlLoader.loadData(String url): Future<Metadata?>
  // → title, image, description 추출
UrlLoader.isValidateUrl(String url): bool
  // → Uri.parse(url).isAbsolute 검사

// url_valid.dart
isValidUrl(String url): Future<bool>
  // → HTTP GET 200 확인
  // → "linkpool://" 프로토콜 제외
```

## 추출 방식
1. `metadata_fetch` 패키지로 OG 태그 파싱
2. 실패 시 `<title>` 태그 fallback
3. User-Agent 스푸핑으로 봇 차단 우회
4. 리디렉트 follow

## 의존성
- `metadata_fetch` (boring-km 커스텀 포크)
- `dio: ^5.4.1`
- `http: ^1.0.0`

## 수정 시 주의사항
- `metadata_fetch`는 커스텀 포크 — pubspec.yaml의 git 참조 확인
- 일부 사이트는 SSR이 아니면 메타데이터 없음 (SPA)
- 타임아웃/에러 시 URL만으로 저장 허용
- 확장프로그램은 Content Script로 추출하지만, 앱은 HTTP 요청으로 추출 (방식 차이)
