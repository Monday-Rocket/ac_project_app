import 'dart:async';

import 'package:ac_project_app/data/provider/login/apple_login.dart';
import 'package:ac_project_app/data/provider/login/google_login.dart';
import 'package:ac_project_app/data/provider/login/kakao_login.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/login/login_type.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  Future<void> login(LoginType loginType) async {
    switch (loginType) {
      case LoginType.apple:
        final result = await Apple.login();
        break;
      case LoginType.google:
        final userCredential = await Google.login();
        Log.i(userCredential?.credential?.token);
        break;
      case LoginType.kakao:
        final result = await Kakao.login();
        break;
    }
    unawaited(Get.toNamed(Routes.home));
  }
}
