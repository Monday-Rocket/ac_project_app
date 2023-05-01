import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailPassword {
  static Future<bool> signedLogin(String? email, String? password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email ?? dotenv.env['TEST_SIGNED_USER_EMAIL'] ?? '',
        password: password ?? dotenv.env['TEST_SIGNED_USER_PASSWORD'] ?? '',
      );
      return userCredential.user != null;
    } catch (e) {
      return false;
    }
  }
}
