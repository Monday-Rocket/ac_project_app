import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_link.g.dart';

@JsonSerializable()
@immutable
class InviteLink {
  const InviteLink({required this.url, required this.token});

  final String? url;
  final String? token;

  factory InviteLink.fromJson(Map<String, dynamic> json) => _$InviteLinkFromJson(json);
  Map<String, dynamic> toJson() => _$InviteLinkToJson(this);
}
