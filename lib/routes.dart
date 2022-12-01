import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/page/my_page/term_page.dart';
import 'package:ac_project_app/ui/page/upload/view/upload_page.dart';
import 'package:ac_project_app/ui/view/change_profile_view.dart';
import 'package:ac_project_app/ui/view/home_view.dart';
import 'package:ac_project_app/ui/view/login_view.dart';
import 'package:ac_project_app/ui/view/link_detail_view.dart';
import 'package:ac_project_app/ui/view/my_link_page.dart';
import 'package:ac_project_app/ui/view/report/report_page.dart';
import 'package:ac_project_app/ui/view/sign_up_job_view.dart';
import 'package:ac_project_app/ui/view/sign_up_nickname_view.dart';
import 'package:ac_project_app/ui/view/splash_view.dart';
import 'package:ac_project_app/ui/view/user_feed_view.dart';
import 'package:flutter/material.dart';

class Routes {
  static const splash = '/splash';

  static const login = '/login';
  static const signUpNickname = '/signUpNickname';
  static const singUpJob = '/signUpJob';

  static const home = '/home';
  static const myLinks = '/myLinks';
  static const linkDetail = '/linkDetail';
  static const userFeed = '/userFeed';

  static const termPage = '/termPage';

  static const myPage = '/myPage';
  static const profile = '/profile';
  static const report = '/report';
  static const upload = '/upload';
}

class Pages {
  static Route<dynamic>? getPages(RouteSettings settings) {
    final arguments = settings.arguments;
    final router = PageRouter(arguments);
    switch (settings.name) {
      case Routes.splash:
        return router.create(child: const SplashView());
      case Routes.login:
        return router.create(child: const LoginView());
      case Routes.home:
        return router.create(child: const HomeView());
      case Routes.myLinks:
        return router.create(child: const MyLinkPage());
      case Routes.linkDetail:
        return router.create(child: const LinkDetailView());
      case Routes.userFeed:
        return router.create(child: const UserFeedView());
      case Routes.signUpNickname:
        return router.create(child: const SignUpNicknameView());
      case Routes.singUpJob:
        return router.create(child: const SignUpJobView());
      case Routes.myPage:
        return router.create(child: const MyPage());
      case Routes.termPage:
        return router.create(child: const TermPage());
      case Routes.profile:
        return router.create(child: const ChangeProfileView());
      case Routes.report:
        return router.create(child: const ReportPage());
      case Routes.upload :
        return router.create(child: UploadPage());
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
