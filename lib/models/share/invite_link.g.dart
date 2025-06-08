// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteLink _$InviteLinkFromJson(Map<String, dynamic> json) => InviteLink(
      folder_id: (json['folder_id'] as num?)?.toInt(),
      folder_name: json['folder_name'] as String?,
      invite_token: json['invite_token'] as String?,
      expires_at: json['expires_at'] as String?,
    );

Map<String, dynamic> _$InviteLinkToJson(InviteLink instance) =>
    <String, dynamic>{
      'folder_id': instance.folder_id,
      'folder_name': instance.folder_name,
      'invite_token': instance.invite_token,
      'expires_at': instance.expires_at,
    };
