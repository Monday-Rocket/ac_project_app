import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.g.dart';

@JsonSerializable(explicitToJson: true)
class ApiResult {

  ApiResult(this.status, this.data, this.error);

  factory ApiResult.fromJson(Map<String, dynamic> json) =>
      _$ApiResultFromJson(json);

  final int? status;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? error;

  Map<String, dynamic> toJson() => _$ApiResultToJson(this);
}
// TODO Converter는 나중에

