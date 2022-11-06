import 'package:freezed_annotation/freezed_annotation.dart';

part 'link.g.dart';

@JsonSerializable()
class Link {
  Link({this.url, this.image, this.folderId,});

  factory Link.fromJson(Map<String, dynamic> json) =>
      _$LinkFromJson(json);

  Map<String, dynamic> toJson() => _$LinkToJson(this);

  String? url;
  String? title;
  String? image;
  String? describe;
  int? folderId;

  @JsonKey(name: 'created_at')
  String? time;
}
