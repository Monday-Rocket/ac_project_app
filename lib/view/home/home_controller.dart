import 'package:get/get_state_manager/get_state_manager.dart';

class HomeController extends GetxController {

  String? greeting;

  @override
  void onInit() {
    Future.delayed(const Duration(seconds: 1), () {
      greeting = '비사이드 12기 먼데이 로켓';
      update();
    });
    super.onInit();
  }
}