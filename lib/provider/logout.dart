import 'dart:async';

import 'package:ac_project_app/provider/login/kakao_login.dart';
import 'package:ac_project_app/provider/login/naver_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void logout(BuildContext context) {
  // 1. 공유패널 비우기
  ShareDataProvider.clearAllData();

  // 2. 로그아웃 하기
  SharedPreferences.getInstance().then((prefs) {
    final loginType = prefs.getString('loginType') ?? '';
    switch (loginType) {
      case 'google':
        GoogleSignIn(
          scopes: [
            'email',
          ],
        ).signOut().then((value) {
          firebaseLogout(context);
        });
        break;
      case 'naver':
        Naver.logout().then((value) => firebaseLogout(context));
        break;
      case 'kakao':
        Kakao.logout().then((value) => firebaseLogout(context));
        break;
      default:
        firebaseLogout(context);
        break;
    }
  });
}

Future<bool> logoutWithoutPush(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('loginType') ?? '';
    switch (loginType) {
      case 'google':
        await GoogleSignIn(
          scopes: [
            'email',
          ],
        ).signOut();
        break;
      case 'naver':
        await Naver.logout();
        break;
      case 'kakao':
        await Kakao.logout();
        break;
      default:
        break;
    }
    await FirebaseAuth.instance.signOut();
    return true;
  } catch (e) {
    return false;
  }
}

void firebaseLogout(BuildContext context) {
  FirebaseAuth.instance.signOut().then((value) {
    Navigator.of(context).pop(true);
    Navigator.pushReplacementNamed(context, Routes.login);
  });
}
