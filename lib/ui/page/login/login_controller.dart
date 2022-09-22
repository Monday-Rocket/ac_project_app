import 'dart:async';

import 'package:ac_project_app/data/provider/login/google_login.dart';
import 'package:ac_project_app/data/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/login/login_type.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  List<String> shareDataList = [];

  Future<void> login(LoginType loginType) async {
    switch (loginType) {
      case LoginType.google:
        final userCredential = await Google.login();
        final firebaseToken = userCredential?.credential?.token;
        Log.i(firebaseToken);
        if (firebaseToken != null) {
          unawaited(Get.toNamed(Routes.home));
        }
        break;
      case LoginType.apple:
        // TODO: Handle this case.
        break;
      case LoginType.kakao:
        // TODO: Handle this case.
        break;
    }
  }

  Future<void> getShareData() async {
    final result = await ShareDataProvider.getShareDataList();
    shareDataList
      ..clear()
      ..addAll(result);
    update();
  }
}
