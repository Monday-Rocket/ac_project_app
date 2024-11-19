import 'dart:async';

import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/provider/login/firebase_auth_remote_data_source.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Naver {
  static Future<bool> login() async {
    final result = await FlutterNaverLogin.logIn();
    final prefs = await SharedPreferences.getInstance();
    unawaited(prefs.setString('loginType', LoginType.naver.name));

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

  static Future<void> logout() async {
    final result = await FlutterNaverLogin.logOutAndDeleteToken();
    if (result.status == NaverLoginStatus.cancelledByUser) {
      Log.d('logout');
    } else {
      Log.d(result.status.name);
    }
  }
}
