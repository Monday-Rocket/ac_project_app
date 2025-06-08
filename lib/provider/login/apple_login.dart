import 'dart:async';

import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Apple {
  static Future<bool> login() async {
    try {
      unawaited(SharedPrefHelper.saveKeyValue('loginType', LoginType.apple.name));
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Firebase Sign in
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
      return userCredential.user != null;
    } catch (error) {
      Log.e(error.toString());
      return false;
    }
  }
}
