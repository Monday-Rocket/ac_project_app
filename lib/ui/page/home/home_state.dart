import 'package:ac_project_app/data/model/today_weather.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

part 'home_state.g.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required TodayWeather todayWeather,
    required bool isNotEmpty,
  }) = _HomeState;
  factory HomeState.fromJson(Map<String, dynamic> json) => _$HomeStateFromJson(json);
}
