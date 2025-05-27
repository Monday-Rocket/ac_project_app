import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_link.g.dart';

@JsonSerializable()
@immutable
class InviteLink {
  const InviteLink({
    this.folder_id,
    this.folder_name,
    this.invite_token,
    this.expires_at,
  });

  factory InviteLink.fromJson(Map<String, dynamic> json) => _$InviteLinkFromJson(json);

  final int? folder_id;
  final String? folder_name;
  final String? invite_token;
  final String? expires_at;

  Map<String, dynamic> toJson() => _$InviteLinkToJson(this);
}
