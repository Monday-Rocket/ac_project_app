// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_HomeState _$$_HomeStateFromJson(Map<String, dynamic> json) => _$_HomeState(
      todayWeather:
          TodayWeather.fromJson(json['todayWeather'] as Map<String, dynamic>),
      isNotEmpty: json['isNotEmpty'] as bool,
    );

Map<String, dynamic> _$$_HomeStateToJson(_$_HomeState instance) =>
    <String, dynamic>{
      'todayWeather': instance.todayWeather,
      'isNotEmpty': instance.isNotEmpty,
    };
