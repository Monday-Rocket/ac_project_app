// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Folder _$FolderFromJson(Map<String, dynamic> json) => Folder(
      id: (json['id'] as num?)?.toInt(),
      thumbnail: json['thumbnail'] as String?,
      visible: json['visible'] as bool?,
      name: json['name'] as String?,
      links: (json['links'] as num?)?.toInt(),
      time: json['created_date_time'] as String?,
      isClassified: json['isClassified'] as bool?,
      membersCount: (json['membersCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FolderToJson(Folder instance) => <String, dynamic>{
      'id': instance.id,
      'thumbnail': instance.thumbnail,
      'visible': instance.visible,
      'name': instance.name,
      'links': instance.links,
      'created_date_time': instance.time,
      'isClassified': instance.isClassified,
      'membersCount': instance.membersCount,
    };
