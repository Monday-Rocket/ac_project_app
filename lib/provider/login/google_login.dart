import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Google {
  static Future<UserCredential?> login() async {
    final _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
    );
    try {
      final account = await _googleSignIn.signIn();
      final authentication = await account?.authentication;

      Log.d('Google idToken: ${authentication?.idToken}');
      Log.d('Google AccessToken: ${authentication?.accessToken}');

      final credential = GoogleAuthProvider.credential(
        accessToken: authentication?.accessToken,
        idToken: authentication?.idToken,
      );

      return FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      Log.e(error);
      return null;
    }
  }
}
