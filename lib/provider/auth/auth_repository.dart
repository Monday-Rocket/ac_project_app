import 'dart:io';

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
    final googleSignIn = GoogleSignIn.instance;
    googleSignIn.initialize(
      serverClientId: _getGoogleServerClientId(),
    );

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null) throw Exception('Google 인증 토큰을 받지 못했습니다');

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    if (response.user == null) throw Exception('Supabase 로그인에 실패했습니다');
    return response.user!;
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
    final user = currentUser;
    if (user == null) return 'free';

    final data = await _client
        .from('profiles')
        .select('plan, plan_expires_at')
        .eq('id', user.id)
        .single();

    final plan = data['plan'] as String? ?? 'free';
    final expiresAt = data['plan_expires_at'] as String?;

    if (plan == 'pro' && expiresAt != null) {
      if (DateTime.parse(expiresAt).isBefore(DateTime.now())) {
        return 'free';
      }
    }

    return plan;
  }

  String _getGoogleServerClientId() {
    if (Platform.isIOS) {
      return '310694628669-8ltau1vabhn2009kuik3nuddh8bs282l.apps.googleusercontent.com';
    }
    return '310694628669-10m2vjbei0f279n1j0etqod97ul9e12k.apps.googleusercontent.com';
  }
}
