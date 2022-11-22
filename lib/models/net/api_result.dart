import 'package:ac_project_app/models/net/api_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.g.dart';

@JsonSerializable(explicitToJson: true)
class ApiResult {
  ApiResult(this.status, this.data, this.error);

  factory ApiResult.fromJson(Map<String, dynamic> json) =>
      _$ApiResultFromJson(json);

  final int? status;
  final ApiError? error;

  final dynamic data;

  Map<String, dynamic> toJson() => _$ApiResultToJson(this);
}
