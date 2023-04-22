import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/view/links/home_view.dart';
import 'package:ac_project_app/ui/view/links/link_detail_view.dart';
import 'package:ac_project_app/ui/view/links/my_link_view.dart';
import 'package:ac_project_app/ui/view/links/search_view.dart';
import 'package:ac_project_app/ui/view/links/user_feed_view.dart';
import 'package:ac_project_app/ui/view/report_view.dart';
import 'package:ac_project_app/ui/view/splash_view.dart';
import 'package:ac_project_app/ui/view/terms_view.dart';
import 'package:ac_project_app/ui/view/tutorial_view.dart';
import 'package:ac_project_app/ui/view/upload_view.dart';
import 'package:ac_project_app/ui/view/profile/change_profile_view.dart';
import 'package:ac_project_app/ui/view/user/email_login_view.dart';
import 'package:ac_project_app/ui/view/user/login_view.dart';
import 'package:ac_project_app/ui/view/user/sign_up_job_view.dart';
import 'package:ac_project_app/ui/view/user/sign_up_nickname_view.dart';
import 'package:flutter/material.dart';

class Routes {
  // links
  static const home = '/home';
  static const linkDetail = '/linkDetail';
  static const myLinks = '/myLinks';
  static const search = '/search';
  static const userFeed = '/userFeed';

  // user
  static const profile = '/profile';
  static const emailLogin = '/emailLogin';
  static const login = '/login';
  static const singUpJob = '/signUpJob';
  static const signUpNickname = '/signUpNickname';

  // etc
  static const splash = '/splash';
  static const terms = '/terms';
  static const myPage = '/myPage';
  static const report = '/report';
  static const upload = '/upload';
  static const tutorial = '/tutorial';
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
      case Routes.home:
        return router.create(child: const HomeView());
      case Routes.myLinks:
        return router.create(child: MyLinkView());
      case Routes.linkDetail:
        return router.create(child: const LinkDetailView());
      case Routes.userFeed:
        return router.create(child: UserFeedView());
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
      case Routes.upload:
        return router.create(child: const UploadView());
      case Routes.tutorial:
        return router.create(child: const TutorialView());
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
