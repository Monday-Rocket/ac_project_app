import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Google {
  static Future<String?> login() async {
    final googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
    );
    try {
      final account = await googleSignIn.signIn();
      final authentication = await account?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: authentication?.accessToken,
        idToken: authentication?.idToken,
      );

      // Firebase Sign in
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return await userCredential.user?.getIdToken();
    } catch (error) {
      Log.e(error);
      return null;
    }
  }
}
