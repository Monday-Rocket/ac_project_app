// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Link _$LinkFromJson(Map<String, dynamic> json) => Link(
      id: (json['id'] as num?)?.toInt(),
      url: json['url'] as String?,
      title: json['title'] as String?,
      image: json['image'] as String?,
      describe: json['describe'] as String?,
      folderId: (json['folderId'] as num?)?.toInt(),
      time: json['created_date_time'] as String?,
      user: json['user'] == null ? null : DetailUser.fromJson(json['user']),
      inflowType: json['inflow_type'] as String?,
    );

Map<String, dynamic> _$LinkToJson(Link instance) => <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'title': instance.title,
      'image': instance.image,
      'describe': instance.describe,
      'folderId': instance.folderId,
      'created_date_time': instance.time,
      'user': instance.user,
      'inflow_type': instance.inflowType,
    };
