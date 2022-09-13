import 'package:ac_project_app/data/model/today_weather.dart';
import 'package:ac_project_app/data/provider/location_provider.dart';
import 'package:ac_project_app/data/repository/weather_repository.dart';
import 'package:ac_project_app/ui/page/home/home_state.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  HomeController(this._weatherRepository);

  final WeatherRepository _weatherRepository;

  HomeState _state = HomeState(
    todayWeather: TodayWeather(),
    isNotEmpty: false,
  );

  HomeState get state => _state;

  @override
  void onInit() {
    Future.microtask(() async {
      _state = state.copyWith(
        todayWeather: await getTodayWeather(),
        isNotEmpty: true,
      );
      update();
    });
    super.onInit();
  }

  Future<TodayWeather> getTodayWeather() async {
    final currentLocation = await LocationProvider.getLocation();
    return _weatherRepository.getWeather(currentLocation);
  }
}
