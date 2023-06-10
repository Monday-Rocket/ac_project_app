import 'dart:async';

import 'package:ac_project_app/provider/kakao/kakao.dart';
import 'package:ac_project_app/provider/login/naver_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void logout(BuildContext context, void Function() callback) {
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
          firebaseLogout(context, callback);
        });
        break;
      case 'naver':
        Naver.logout().then((value) => firebaseLogout(context, callback));
        break;
      case 'kakao':
        Kakao.logout().then((value) => firebaseLogout(context, callback));
        break;
      default:
        firebaseLogout(context, callback);
        break;
    }
  });
}

Future<bool> logoutWithoutPush(FirebaseAuth auth) async {
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
    await auth.signOut();
    return true;
  } catch (e) {
    return false;
  }
}

void firebaseLogout(BuildContext context, void Function() callback) {
  FirebaseAuth.instance.signOut().then((value) {
    callback();
  });
}
