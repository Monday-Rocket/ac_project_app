import 'package:ac_project_app/ui/view/home_view.dart';
import 'package:ac_project_app/ui/view/login_view.dart';
import 'package:ac_project_app/ui/view/my_link_view.dart';
import 'package:ac_project_app/ui/view/sign_up_job_view.dart';
import 'package:ac_project_app/ui/view/sign_up_nickname_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Routes {
  static const login = '/login';
  static const signUpNickname = '/signUpNickname';
  static const singUpJob = '/signUpJob';

  static const home = '/home';
  static const myLinks = '/myLinks';
}

class Pages {
  static Route<dynamic>? getPages(RouteSettings settings) {
    final arguments = settings.arguments;
    final router = PageRouter(arguments);
    switch (settings.name) {
      case Routes.login:
        /*
          TODO 다른 로그인 추가 예정
         */
        return router.create(child: const LoginView());
      case Routes.home:
        return router.create(child: const HomeView());
      case Routes.myLinks:
        return router.create(child: const MyLinkView());
      case Routes.signUpNickname:
        return router.create(child: const SignUpNicknameView());
      case Routes.singUpJob:
        return router.create(child: const SignUpJobView());
      default:
        return null;
    }
  }
}

class PageRouter {
  PageRouter(this.arguments);

  final Object? arguments;

  PageRoute<dynamic> create({
    required Widget child,
    bool? maintainState = true,
    bool? fullscreenDialog = false,
  }) {
    return MaterialPageRoute(
      builder: (context) => child,
      settings: RouteSettings(
        arguments: arguments,
      ),
      maintainState: maintainState!,
      fullscreenDialog: fullscreenDialog!,
    );
  }
}
