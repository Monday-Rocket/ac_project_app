// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResult _$ApiResultFromJson(Map<String, dynamic> json) => ApiResult(
      json['status'] as int?,
      json['data'] as Map<String, dynamic>?,
      json['error'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ApiResultToJson(ApiResult instance) => <String, dynamic>{
      'status': instance.status,
      'data': instance.data,
      'error': instance.error,
    };
