import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<User> signInWithGoogle() async {
    // Supabase signInWithIdToken 은 "id_token 의 nonce claim 과 전달한 nonce 가
    // 둘 다 있거나 둘 다 없어야" 한다. google_sign_in 7.x 는 id_token 에 nonce
    // claim 을 포함시켜 돌려주므로, 우리가 rawNonce 를 만들어 initialize 에는
    // sha256(rawNonce) 를, Supabase 에는 rawNonce 원본을 넘긴다.
    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: _getGoogleServerClientId(),
      nonce: hashedNonce,
    );

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null) throw Exception('Google 인증 토큰을 받지 못했습니다');

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: rawNonce,
    );

    if (response.user == null) throw Exception('Supabase 로그인에 실패했습니다');
    return response.user!;
  }

  String _generateRawNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)])
        .join();
  }

  Future<User> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Apple 인증 토큰을 받지 못했습니다');

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
    );

    if (response.user == null) throw Exception('Supabase 로그인에 실패했습니다');
    return response.user!;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  Future<String> getPlan() async {
    final info = await getPlanInfo();
    return info.effectivePlan;
  }

  /// plan + 만료일을 함께 반환. 만료 체크는 호출자 쪽에서 하거나
  /// [PlanInfo.effectivePlan] 을 사용.
  Future<PlanInfo> getPlanInfo() async {
    final user = currentUser;
    if (user == null) return const PlanInfo(plan: 'free', expiresAt: null);

    final data = await _client
        .from('profiles')
        .select('plan, plan_expires_at')
        .eq('id', user.id)
        .single();

    final plan = data['plan'] as String? ?? 'free';
    final expiresAtRaw = data['plan_expires_at'] as String?;
    final expiresAt =
        expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);
    return PlanInfo(plan: plan, expiresAt: expiresAt);
  }

  String _getGoogleServerClientId() {
    if (Platform.isIOS) {
      return '310694628669-8ltau1vabhn2009kuik3nuddh8bs282l.apps.googleusercontent.com';
    }
    // Android / 기타 플랫폼: Web application 타입 Client ID 사용
    // (Chrome Extension 과 공유하는 Web Client ID — Supabase Authorized Client IDs 에
    //  이미 등록되어 있음)
    return '310694628669-cm6c89tss9g8vbp5dtd173gpe64bs0on.apps.googleusercontent.com';
  }
}

class PlanInfo {
  const PlanInfo({required this.plan, required this.expiresAt});

  final String plan;
  final DateTime? expiresAt;

  /// 만료 시각까지 고려한 실사용 plan. 만료된 'pro'는 'free'로 강등.
  String get effectivePlan {
    if (plan != 'pro') return plan;
    if (expiresAt == null) return 'pro';
    return expiresAt!.isAfter(DateTime.now()) ? 'pro' : 'free';
  }
}
