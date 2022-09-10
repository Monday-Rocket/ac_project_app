import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/data/provider/weather_api.dart';
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
}
