import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/view/home_view.dart';
import 'package:ac_project_app/ui/view/links/link_detail_view.dart';
import 'package:ac_project_app/ui/view/links/my_link_view.dart';
import 'package:ac_project_app/ui/view/links/search_view.dart';
import 'package:ac_project_app/ui/view/links/shared_link_setting_view.dart';
import 'package:ac_project_app/ui/view/oss_licenses_view.dart';
import 'package:ac_project_app/ui/view/splash_view.dart';
import 'package:ac_project_app/ui/view/tutorial_view.dart';
import 'package:ac_project_app/ui/view/upload_view.dart';
import 'package:flutter/material.dart';

class Routes {
  // links
  static const home = '/home';
  static const linkDetail = '/linkDetail';
  static const myLinks = '/myLinks';
  static const search = '/search';
  static const sharedLinkSetting = '/sharedLinkSetting';

  // etc
  static const splash = '/splash';
  static const myPage = '/myPage';
  static const upload = '/upload';
  static const tutorial = '/tutorial';
  static const ossLicenses = '/ossLicenses';
}

class Pages {
  static Route<dynamic>? getPages(RouteSettings settings) {
    final arguments = settings.arguments;
    final router = PageRouter(arguments);
    switch (settings.name) {
      case Routes.splash:
        return router.create(child: const SplashView());
      case Routes.home:
        return router.create(child: const HomeView());
      case Routes.myLinks:
        return router.create(child: MyLinkView());
      case Routes.linkDetail:
        return router.create(child: const LinkDetailView());
      case Routes.myPage:
        return router.create(child: const MyPage());
      case Routes.search:
        return router.create(child: const SearchView());
      case Routes.upload:
        return router.create(child: UploadView(args: arguments as Map<String, dynamic>?));
      case Routes.tutorial:
        return router.create(child: const TutorialView());
      case Routes.ossLicenses:
        return router.create(child: const OssLicensesView());
      case Routes.sharedLinkSetting:
        return router.create(child: const SharedLinkSettingView());
      default:
        if (settings.name != null && ((settings.name?.startsWith('linkpool://') ?? false) || (settings.name?.startsWith('kakao') ?? false))) {
          return router.create(child: const SplashView());
        }
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
