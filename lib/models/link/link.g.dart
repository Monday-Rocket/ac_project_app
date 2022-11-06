// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Link _$LinkFromJson(Map<String, dynamic> json) => Link(
      url: json['url'] as String?,
      image: json['image'] as String?,
      folderId: json['folderId'] as int?,
    )
      ..title = json['title'] as String?
      ..describe = json['describe'] as String?
      ..time = json['created_at'] as String?;

Map<String, dynamic> _$LinkToJson(Link instance) => <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'image': instance.image,
      'describe': instance.describe,
      'folderId': instance.folderId,
      'created_at': instance.time,
    };
