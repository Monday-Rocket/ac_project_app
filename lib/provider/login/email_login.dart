import 'dart:async';

import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Email {
  static Future<bool> login(String email, String emailLink) async {
    final prefs = await SharedPreferences.getInstance();
    unawaited(prefs.setString('loginType', 'email'));
    final userCredential = await FirebaseAuth.instance.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    return userCredential.user != null;
  }

  static Future<void> send(String email) async {
    try {
      Log.i('이메일 전송');
      await FirebaseAuth.instance
          .sendSignInLinkToEmail(
            email: email,
            actionCodeSettings: ActionCodeSettings(
              url: 'https://acprojectapp.page.link/jTpt?email=$email',
              handleCodeInApp: true,
              iOSBundleId: 'com.mr.acProjectApp',
              androidPackageName: 'com.mr.ac_project_app',
            ),
          )
          .catchError(Log.e)
          .then((value) => Fluttertoast.showToast(msg: '이메일 전송됨'));
    } catch (e) {
      Log.e(e.toString());
    }
  }
}
