// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Folder _$FolderFromJson(Map<String, dynamic> json) => Folder(
      id: json['id'] as int?,
      imageUrl: json['imageUrl'] as String?,
      private: json['private'] as bool?,
      name: json['name'] as String?,
      linkCount: json['linkCount'] as int?,
    );

Map<String, dynamic> _$FolderToJson(Folder instance) => <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'private': instance.private,
      'name': instance.name,
      'linkCount': instance.linkCount,
    };