import 'dart:io';

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
    final router = MultiPlatformPageRoute(arguments);
    switch (settings.name) {
      case Routes.login:
        /*
          TODO 다른 로그인 추가 예정
         */
        return router.create(
          builder: (_) => const LoginView(),
        );
      case Routes.home:
        return router.create(
          builder: (_) => const HomeView(),
        );
      case Routes.myLinks:
        return router.create(
          builder: (_) => const MyLinkView(),
        );
      case Routes.signUpNickname:
        return router.create(
          builder: (_) => const SignUpNicknameView(),
        );
      case Routes.singUpJob:
        return router.create(
          builder: (_) => const SignUpJobView(),
        );
      default:
        return null;
    }
  }
}

class MultiPlatformPageRoute {
  MultiPlatformPageRoute(this.arguments);

  final Object? arguments;

  PageRoute<dynamic> create({
    required Widget Function(BuildContext) builder,
    bool? maintainState = true,
    bool? fullscreenDialog = true,
  }) {
    if (Platform.isAndroid) {
      return MaterialPageRoute(
        builder: builder,
        settings: RouteSettings(
          arguments: arguments,
        ),
        maintainState: maintainState!,
        fullscreenDialog: fullscreenDialog!,
      );
    } else if (Platform.isIOS) {
      return CupertinoPageRoute(
        builder: builder,
        settings: RouteSettings(
          arguments: arguments,
        ),
        maintainState: maintainState!,
        fullscreenDialog: fullscreenDialog!,
      );
    } else {
      throw Exception('Platform 미지원');
    }
  }
}
