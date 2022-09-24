import 'package:ac_project_app/models/today_weather.dart';
import 'package:ac_project_app/provider/location_provider.dart';
import 'package:ac_project_app/provider/api/weather/weather_api.dart';
import 'package:ac_project_app/provider/api/weather/weather_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WeatherCubit extends Cubit<TodayWeather?> {
  WeatherCubit(super.initialState);

  final WeatherRepository _weatherRepository =
      WeatherRepository(WeatherApi(Dio()));

  Future<void> getTodayWeather() async {
    final currentLocation = await LocationProvider.getLocation();
    final todayWeather = await _weatherRepository.getWeather(currentLocation);
    emit(todayWeather);
  }
}
