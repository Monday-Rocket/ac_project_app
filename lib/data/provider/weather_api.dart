import 'package:ac_project_app/data/model/open_weather.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'weather_api.g.dart';

@RestApi(baseUrl: 'https://api.openweathermap.org')
abstract class WeatherApi {
  factory WeatherApi(Dio dio, {String baseUrl}) = _WeatherApi;

  @GET('/data/2.5/weather?lat={lat}&lon={lon}&appid={apiKey}')
  Future<OpenWeather> getData(
    @Path('lat') String lat,
    @Path('lon') String lon,
    @Path('apiKey') String apiKey,
  );
}
