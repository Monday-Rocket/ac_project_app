import 'package:ac_project_app/data/model/location.dart';
import 'package:ac_project_app/data/model/today_weather.dart';
import 'package:ac_project_app/data/provider/weather_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherRepository {
  WeatherRepository(this._client);

  final WeatherApi _client;

  Future<TodayWeather> getWeather(Location position) async {
    final weather = await _client.getData(
      position.lat.toString(),
      position.lon.toString(),
      dotenv.env['weather.api.key'] ?? '',
    );
    return TodayWeather(
      city: weather.name,
      sunrise: weather.sys?.sunrise,
      sunset: weather.sys?.sunset,
      temp: weather.main?.temp,
      humidity: weather.main?.humidity,
      weather: weather.weather?[0].main,
      lat: position.lat,
      lon: position.lon,
    );
  }
}
