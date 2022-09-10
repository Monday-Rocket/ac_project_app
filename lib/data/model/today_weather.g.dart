// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodayWeather _$TodayWeatherFromJson(Map<String, dynamic> json) => TodayWeather(
      city: json['city'] as String?,
      sunrise: json['sunrise'] as int?,
      sunset: json['sunset'] as int?,
      temp: (json['temp'] as num?)?.toDouble(),
      humidity: json['humidity'] as int?,
      weather: json['weather'] as String?,
    );

Map<String, dynamic> _$TodayWeatherToJson(TodayWeather instance) =>
    <String, dynamic>{
      'city': instance.city,
      'sunrise': instance.sunrise,
      'sunset': instance.sunset,
      'temp': instance.temp,
      'humidity': instance.humidity,
      'weather': instance.weather,
    };
