import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/view/change_profile_view.dart';
import 'package:ac_project_app/ui/view/email_login_view.dart';
import 'package:ac_project_app/ui/view/email_sign_up_view.dart';
import 'package:ac_project_app/ui/view/home_view.dart';
import 'package:ac_project_app/ui/view/link_detail_view.dart';
import 'package:ac_project_app/ui/view/login_view.dart';
import 'package:ac_project_app/ui/view/my_link_page.dart';
import 'package:ac_project_app/ui/view/report_view.dart';
import 'package:ac_project_app/ui/view/search_view.dart';
import 'package:ac_project_app/ui/view/sign_up_job_view.dart';
import 'package:ac_project_app/ui/view/sign_up_nickname_view.dart';
import 'package:ac_project_app/ui/view/splash_view.dart';
import 'package:ac_project_app/ui/view/terms_view.dart';
import 'package:ac_project_app/ui/view/user_feed_view.dart';
import 'package:flutter/material.dart';

class Routes {
  static const splash = '/splash';

  static const login = '/login';
  static const terms = '/terms';
  static const emailLogin = '/emailLogin';
  static const emailSignUp = '/emailSignUp';

  static const signUpNickname = '/signUpNickname';
  static const singUpJob = '/signUpJob';

  static const home = '/home';
  static const myLinks = '/myLinks';
  static const linkDetail = '/linkDetail';
  static const userFeed = '/userFeed';

  static const myPage = '/myPage';
  static const profile = '/profile';

  static const search = '/search';

  static const report = '/report';
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
      case Routes.terms:
        return router.create(child: const TermsView());
      case Routes.emailLogin:
        return router.create(child: const EmailLoginView());
      case Routes.emailSignUp:
        return router.create(child: const EmailSignUpView());
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
      case Routes.profile:
        return router.create(child: const ChangeProfileView());
      case Routes.search:
        return router.create(child: const SearchView());
      case Routes.report:
        return router.create(child: const ReportView());
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
