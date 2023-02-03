import 'package:ac_project_app/provider/login/firebase_auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class Naver {
  static Future<bool> login() async {
    final result = await FlutterNaverLogin.logIn();

    if (result.status == NaverLoginStatus.loggedIn) {
      final customToken = await FirebaseAuthRemoteDataSource().createCustomToken({
        'uid': result.account.id,
        'serviceName': 'naver',
      });
      final userCredential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
      return userCredential.user != null;
    } else {
      return false;
    }
  }
}
