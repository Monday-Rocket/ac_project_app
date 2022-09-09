import 'package:ac_project_app/bindings.dart';
import 'package:ac_project_app/ui/page/home/home_view.dart';
import 'package:ac_project_app/ui/page/login/login_view.dart';
import 'package:get/route_manager.dart';

class Routes {
  static const login = '/login';
  static const home = '/home';
}

class Pages {
  static final pages = [
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeViewBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginViewBinding(),
    ),
  ];
}
