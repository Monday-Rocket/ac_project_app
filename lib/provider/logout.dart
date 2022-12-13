import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void logout(BuildContext context) {

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

void firebaseLogout(BuildContext context) {
  FirebaseAuth.instance.signOut().then((value) {
    Navigator.of(context).pop(true);
    Navigator.pushReplacementNamed(context, Routes.login);
  });
}
