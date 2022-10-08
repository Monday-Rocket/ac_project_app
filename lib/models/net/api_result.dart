import 'package:ac_project_app/models/net/api_error.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.g.dart';

@JsonSerializable(explicitToJson: true)
class ApiResult<T> {
  ApiResult(this.status, this.data, this.error);

  factory ApiResult.fromJson(Map<String, dynamic> json) =>
      _$ApiResultFromJson(json);

  final int? status;
  final ApiError? error;

  @DataConverter<dynamic>()
  final T? data;

  Map<String, dynamic> toJson() => _$ApiResultToJson(this);
}

class DataConverter<T> implements JsonConverter<T, Object?> {
  const DataConverter();

  @override
  T fromJson(Object? json) {
    if (json is Map<String, dynamic>) {
      switch (T) {
        case User:
          return User.fromJson(json) as T;
        case DetailUser:
          return DetailUser.fromJson(json) as T;
        case JobGroup:
          return JobGroup.fromJson(json) as T;
      }
    }
    if (json is List && json.isNotEmpty) {
      final resultList = <dynamic>[];
      for (final item in json) {
        resultList.add(fromJson(item as Map<String, dynamic>));
      }
      return resultList as T;
    }
    return json as T;
  }

  @override
  Object? toJson(T object) => object;
}
