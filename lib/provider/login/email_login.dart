import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://acprojectapp.page.link/jTpt',
          handleCodeInApp: true,
          androidInstallApp: true,
          iOSBundleId: 'com.mr.acProjectApp',
          androidPackageName: 'com.mr.ac_project_app',
        ),
      ).catchError(Log.e).then((value) => Log.i('이메일 전송 성공'));
    } catch (e) {
      Log.e(e.toString());
    }
  }
}
