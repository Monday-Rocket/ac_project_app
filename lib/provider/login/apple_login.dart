import 'package:ac_project_app/util/logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Apple {
  static Future<AuthorizationCredentialAppleID?> login() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
        ],
      );

      Log.d('authCode: ${appleCredential.authorizationCode}');
      Log.d('token: ${appleCredential.identityToken}');
      return appleCredential;
    } catch (error) {
      Log.e(error.toString());
      return null;
    }
  }
}
