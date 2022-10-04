import 'package:ac_project_app/models/net/api_error.dart';
import 'package:ac_project_app/models/user.dart';
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
  final T data;

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
      }
    }
    return json as T;
  }

  @override
  Object? toJson(T object) => object;
}
