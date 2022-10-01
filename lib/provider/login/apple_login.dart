import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Apple {
  static Future<String?> login() async {
    try {
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
      return await userCredential.user?.getIdToken();
    } catch (error) {
      Log.e(error.toString());
      return null;
    }
  }
}
