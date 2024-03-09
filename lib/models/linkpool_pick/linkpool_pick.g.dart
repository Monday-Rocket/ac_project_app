// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linkpool_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkpoolPick _$LinkpoolPickFromJson(Map<String, dynamic> json) => LinkpoolPick(
      id: json['id'] as int,
      backgroundColor: json['backgroundColor'] as String,
      title: json['title'] as String,
      image: json['image'] as String,
      describe: json['describe'] as String,
      linkId: json['linkId'] as int,
    );

Map<String, dynamic> _$LinkpoolPickToJson(LinkpoolPick instance) =>
    <String, dynamic>{
      'id': instance.id,
      'backgroundColor': instance.backgroundColor,
      'title': instance.title,
      'image': instance.image,
      'describe': instance.describe,
      'linkId': instance.linkId,
    };
