// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResult<T> _$ApiResultFromJson<T>(Map<String, dynamic> json) => ApiResult<T>(
      json['status'] as int?,
      DataConverter<T>().fromJson(json['data']),
      json['error'] == null
          ? null
          : ApiError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ApiResultToJson<T>(ApiResult<T> instance) =>
    <String, dynamic>{
      'status': instance.status,
      'error': instance.error?.toJson(),
      'data': DataConverter<T>().toJson(instance.data),
    };
