import 'package:json_annotation/json_annotation.dart';

part 'today_weather.g.dart';

@JsonSerializable(explicitToJson: true)
class TodayWeather {
  TodayWeather({
    this.city,
    this.sunrise,
    this.sunset,
    this.temp,
    this.humidity,
    this.weather,
    this.lat,
    this.lon,
  });

  factory TodayWeather.fromJson(Map<String, dynamic> json) =>
      _$TodayWeatherFromJson(json);

  Map<String, dynamic> toJson() => _$TodayWeatherToJson(this);

  final String? city;
  final int? sunrise;
  final int? sunset;
  final double? temp;
  final int? humidity;
  final String? weather;
  final double? lat;
  final double? lon;
}
