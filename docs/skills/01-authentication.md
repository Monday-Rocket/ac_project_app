---
name: app-authentication
description: Flutter 앱 인증 — Google/Apple 로그인, Supabase Auth, Pro 플랜 확인
type: feature
project: ac_project_app
tier: core
---

# 인증 및 사용자 관리 (Authentication)

## 개요
Google/Apple OAuth 로그인 → Supabase Auth 세션. Pro 구독 상태 확인 및 프로필 관리.

## 주요 파일
- `lib/cubits/auth/auth_cubit.dart` — 인증 상태 관리 Cubit
- `lib/provider/auth/auth_repository.dart` — Supabase Auth 래퍼
- `lib/ui/page/my_page/my_page.dart` — 로그인/로그아웃 UI, 프로필 표시

## 인증 플로우
```
1. Google Sign-In / Sign in with Apple
2. OAuth 토큰 → Supabase signInWithIdToken()
3. 세션 발급 → auth state stream 구독
4. profiles 테이블에서 plan, plan_expires_at 조회
5. Pro 여부 판단
```

## Pro 판단 로직
```dart
isPro = profile.plan == 'pro' 
  && (profile.planExpiresAt == null || profile.planExpiresAt.isAfter(DateTime.now()))
```

## 의존성
- `google_sign_in: ^7.2.0`
- `sign_in_with_apple: ^7.0.1`
- `supabase_flutter: ^2.12.2`

## Supabase 테이블
- `profiles` (id, plan, plan_expires_at, created_at, updated_at)

## 수정 시 주의사항
- iOS: Apple 로그인은 App Store 심사 필수 요건
- Android: Google Play Console에서 SHA-1 등록 필요
- Auth state 변경 시 stream listener가 UI 자동 갱신
