import 'package:ac_project_app/data/model/today_weather.dart';
import 'package:ac_project_app/data/provider/weather_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class WeatherRepository {
  WeatherRepository(this._client);

  final WeatherApi _client;

  Future<TodayWeather> getWeather() async {
    final position = await _determinePosition();
    final weather = await _client.getData(
      position.latitude.toString(),
      position.longitude.toString(),
      dotenv.env['weather.api.key'] ?? '',
    );
    return TodayWeather(
      city: weather.name,
      sunrise: weather.sys?.sunrise,
      sunset: weather.sys?.sunset,
      temp: weather.main?.temp,
      humidity: weather.main?.humidity,
      weather: weather.weather?[0].main,
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
