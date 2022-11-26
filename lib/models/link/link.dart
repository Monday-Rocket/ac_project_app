import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'link.g.dart';

@JsonSerializable()
class Link {
  Link({
    this.id,
    this.url,
    this.title,
    this.image,
    this.describe,
    this.folderId,
    this.time,
    this.user,
  });

  factory Link.fromJson(Map<String, dynamic> json) => _$LinkFromJson(json);

  Map<String, dynamic> toJson() => _$LinkToJson(this);

  int? id;
  String? url;
  String? title;
  String? image;
  String? describe;
  int? folderId;

  @JsonKey(name: 'created_date_time')
  String? time;

  final DetailUser? user;
}
