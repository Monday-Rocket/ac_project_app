import 'dart:async';

import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Email {
  static Future<bool> login(String email, String emailLink) async {
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
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        unawaited(Fluttertoast.showToast(msg: 'listen dynamicLinkData'));
        Log.i('onLink[${dynamicLinkData.link}]');
      }).onError((error) {
        unawaited(Fluttertoast.showToast(msg: 'error dynamicLinkData: $error'));
        Log.i('onLink.onError[$error]');
      });
    } catch (e) {
      Log.e(e.toString());
    }
  }
}
