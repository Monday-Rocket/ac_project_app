import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      default:
        firebaseLogout(context);
        break;
    }
  });
}

Future<bool> logoutWithoutPush() async {
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
        await FirebaseAuth.instance.signOut();
        break;
      default:
        await FirebaseAuth.instance.signOut();
        break;
    }
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
