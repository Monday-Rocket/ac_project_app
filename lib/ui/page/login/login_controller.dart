import 'dart:async';

import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/login/login_type.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  void login(LoginType loginType) {
    unawaited(Get.toNamed(Routes.home));
  }
}
