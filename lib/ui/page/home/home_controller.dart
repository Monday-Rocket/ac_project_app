import 'package:get/get_state_manager/get_state_manager.dart';

class HomeController extends GetxController {

  String? greeting;

  @override
  void onInit() {
    Future.delayed(const Duration(seconds: 1), () {
      greeting = '날씨 정보 가져오기';
      update();
    });
    super.onInit();
  }
}