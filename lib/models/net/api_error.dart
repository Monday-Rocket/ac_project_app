import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  ApiError(this.message);

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  factory ApiError.nullObject() => ApiError('');

  final String message;

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
