// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Folder _$FolderFromJson(Map<String, dynamic> json) => Folder(
      id: json['id'] as int?,
      thumbnail: json['thumbnail'] as String?,
      visible: json['visible'] as bool?,
      name: json['name'] as String?,
      links: json['links'] as int?,
      time: json['created_date_time'] as String?,
    );

Map<String, dynamic> _$FolderToJson(Folder instance) => <String, dynamic>{
      'id': instance.id,
      'thumbnail': instance.thumbnail,
      'visible': instance.visible,
      'name': instance.name,
      'links': instance.links,
      'created_date_time': instance.time,
    };
