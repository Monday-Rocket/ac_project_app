import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/models/location.dart';
import 'package:ac_project_app/provider/api/weather/weather_api.dart';
import 'package:ac_project_app/provider/api/weather/weather_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {

  // TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.testLoad(fileInput: File('.env').readAsStringSync());

  final logger = Logger(printer: PrettyPrinter());
  final dio = Dio();
  final client = WeatherApi(dio);
  
  test('weather api 호출 테스트', () async {
    final what = await client.getData('44.34', '10.99', dotenv.env['weather.api.key'] ?? '');
    logger.i(jsonDecode(jsonEncode(what)));
  });

  test('today 날씨 테스트', () async {
    final today = await WeatherRepository(client).getWeather(Location(44.34, 10.99));
    logger.i(jsonDecode(jsonEncode(today)));
  });
}
