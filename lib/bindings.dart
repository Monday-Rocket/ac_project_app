import 'package:ac_project_app/data/provider/location_provider.dart';
import 'package:ac_project_app/data/provider/weather_api.dart';
import 'package:ac_project_app/data/repository/weather_repository.dart';
import 'package:ac_project_app/ui/page/home/home_controller.dart';
import 'package:ac_project_app/ui/page/login/login_controller.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class HomeViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(WeatherRepository(WeatherApi(Dio()))));
  }
}

class LoginViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LoginController());
  }
}
