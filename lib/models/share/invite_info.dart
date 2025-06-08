import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_info.g.dart';

@JsonSerializable()
@immutable
class InviteInfo {
  const InviteInfo(
      {required this.hostId,
      required this.hostName,
      required this.folderId,
      required this.folderName});

  final int? hostId;
  final String? hostName;
  final int? folderId;
  final String? folderName;

  factory InviteInfo.fromJson(Map<String, dynamic> json) =>
      _$InviteInfoFromJson(json);

  Map<String, dynamic> toJson() => _$InviteInfoToJson(this);
}
