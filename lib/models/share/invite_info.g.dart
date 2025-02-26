// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteInfo _$InviteInfoFromJson(Map<String, dynamic> json) => InviteInfo(
      hostId: (json['hostId'] as num?)?.toInt(),
      hostName: json['hostName'] as String?,
      folderId: (json['folderId'] as num?)?.toInt(),
      folderName: json['folderName'] as String?,
    );

Map<String, dynamic> _$InviteInfoToJson(InviteInfo instance) =>
    <String, dynamic>{
      'hostId': instance.hostId,
      'hostName': instance.hostName,
      'folderId': instance.folderId,
      'folderName': instance.folderName,
    };
