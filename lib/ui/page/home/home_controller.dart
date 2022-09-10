import 'package:ac_project_app/data/model/today_weather.dart';
import 'package:ac_project_app/data/repository/weather_repository.dart';
import 'package:ac_project_app/ui/page/home/home_state.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  HomeController(this._weatherRepository);

  final WeatherRepository _weatherRepository;

  Rx<HomeState> _state = HomeState(
    todayWeather: TodayWeather(),
    isNotEmpty: false,
  ).obs;

  HomeState get state => _state.value;

  @override
  void onInit() {
    Future.delayed(const Duration(seconds: 1), () async {
      _state = state.copyWith(
        todayWeather: await getTodayWeather(),
        isNotEmpty: true,
      ).obs;
      update();
    });
    super.onInit();
  }

  Future<TodayWeather> getTodayWeather() async {
    return _weatherRepository.getWeather();
  }
}
