import 'package:ac_project_app/util/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Google {
  static Future<GoogleSignInAuthentication?> login() async {
    final _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
    );
    try {
      final account = await _googleSignIn.signIn();
      final authentication = await account?.authentication;
      Log.d(account);
      Log.d('Google idToken: ${authentication?.idToken}');
      Log.d('Google AccessToken: ${authentication?.accessToken}');
      return authentication;
    } catch (error) {
      Log.e(error);
      return null;
    }
  }
}
