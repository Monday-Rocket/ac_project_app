import 'package:ac_project_app/view/home/home_controller.dart';
import 'package:get/get.dart';

class HomeViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}
