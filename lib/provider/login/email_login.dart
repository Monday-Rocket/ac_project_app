import 'dart:async';

import 'package:ac_project_app/ui/widget/dialog.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  static Future<void> send(
      BuildContext context, String email, String type) async {
    try {
      Log.i('이메일 전송');
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://acprojectapp.page.link/jTpt?email=$email',
          handleCodeInApp: true,
          iOSBundleId: 'com.mr.acProjectApp',
          androidPackageName: 'com.mr.ac_project_app',
        ),
      )
          .catchError((dynamic error) {
        showPopUp(
          title: '인증 실패',
          content: '다른 계정으로 시도 해보세요\nerror: ${error.toString()}',
          parentContext: context,
          callback: () => Navigator.pop(context),
          icon: true,
        );
      }).then((value) {
        showPopUp(
          title: '인증 메일 발송',
          content: '메일주소로 인증 메일이 발송되었습니다\n'
              '이메일의 링크로 $type을 완료해주세요',
          parentContext: context,
          callback: () => Navigator.pop(context),
          icon: true,
        );
      });
    } catch (e) {
      Log.e(e.toString());
    }
  }
}
