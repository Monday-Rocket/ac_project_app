import 'dart:async';

import 'package:ac_project_app/provider/kakao/kakao.dart';
import 'package:ac_project_app/provider/login/naver_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void logout(void Function() callback) {
  // 1. 공유패널 비우기
  ShareDataProvider.clearAllData();

  // 2. 로그아웃 하기
  SharedPrefHelper.getValueFromKey<String>('loginType').then((loginType) {
    switch (loginType) {
      case 'google':
        GoogleSignIn(
          scopes: [
            'email',
          ],
        ).signOut().then((value) {
          firebaseLogout(callback);
        });
        break;
      case 'naver':
        Naver.logout().then((value) => firebaseLogout(callback));
        break;
      case 'kakao':
        Kakao.logout().then((value) => firebaseLogout(callback));
        break;
      default:
        firebaseLogout(callback);
        break;
    }
  });
}

Future<bool> logoutWithoutPush(FirebaseAuth auth) async {
  try {
    final loginType = await SharedPrefHelper.getValueFromKey<String>('loginType');

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

void firebaseLogout(void Function() callback) {
  FirebaseAuth.instance.signOut().then((value) {
    callback();
  });
}
