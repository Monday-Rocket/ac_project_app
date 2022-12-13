// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as int,
      reasonType: json['reasonType'] as String,
      otherReason: json['otherReason'] as String?,
    );

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
      'targetType': instance.targetType,
      'targetId': instance.targetId,
      'reasonType': instance.reasonType,
      'otherReason': instance.otherReason,
    };
