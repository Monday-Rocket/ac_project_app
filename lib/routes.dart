import 'package:ac_project_app/bindings.dart';
import 'package:ac_project_app/view/home/home_view.dart';
import 'package:get/route_manager.dart';

class Routes {
  static const home = '/home';
}

class Pages {
  static final pages = [
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeViewBinding(),
    ),
  ];
}
