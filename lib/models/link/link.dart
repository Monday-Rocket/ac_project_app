import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'link.g.dart';

@JsonSerializable()
class Link extends Equatable {
  const Link({
    this.id,
    this.url,
    this.title,
    this.image,
    this.describe,
    this.folderId,
    this.time,
    this.inflowType,
  });

  factory Link.fromJson(Map<String, dynamic> json) => _$LinkFromJson(json);

  Map<String, dynamic> toJson() => _$LinkToJson(this);

  final int? id;
  final String? url;
  final String? title;
  final String? image;
  final String? describe;
  @JsonKey(name: 'folder_id')
  final int? folderId;

  @JsonKey(name: 'created_date_time')
  final String? time;

  @JsonKey(name: 'inflow_type')
  final String? inflowType;

  Link copyWith({
    int? id,
    String? url,
    String? title,
    String? image,
    String? describe,
    int? folderId,
    String? time,
    String? inflowType,
  }) {
    return Link(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      image: image ?? this.image,
      describe: describe ?? this.describe,
      folderId: folderId ?? this.folderId,
      time: time ?? this.time,
      inflowType: inflowType ?? this.inflowType,
    );
  }

  @override
  List<Object?> get props =>
      [id, url, title, image, describe, folderId, time, inflowType];
}
