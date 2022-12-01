import 'dart:async';

import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Google {
  static Future<bool> login() async {
    final prefs = await SharedPreferences.getInstance();
    unawaited(prefs.setString('loginType', LoginType.google.name));

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
      return userCredential.user != null;
    } catch (error) {
      Log.e(error);
      return false;
    }
  }
}
