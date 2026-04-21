// ignore_for_file: hash_and_equals

import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.g.dart';

@JsonSerializable()
@immutable
class Folder {
  const Folder({
    this.id,
    this.thumbnail,
    this.name,
    this.links,
    this.time,
    this.isClassified,
    this.parentId,
    this.linksTotal,
  });

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  Map<String, dynamic> toJson() => _$FolderToJson(this);

  final int? id;
  final String? thumbnail;
  final String? name;
  final int? links;
  @JsonKey(name: 'created_date_time') final String? time;
  final bool? isClassified;
  final int? parentId;
  // 재귀 링크 카운트 (자기 + 모든 후손). UI 계층 표시용, 직렬화 제외.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? linksTotal;

  static bool containsNameFromFolderList(List<Folder> folders, String? value) {
    return folders.map((folder) => folder.name).toList().contains(value ?? '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Folder &&
      other.id == id &&
      other.thumbnail == thumbnail &&
      other.name == name &&
      other.links == links;
  }

  List<Object?> get props => [id, thumbnail, name, links];


  Folder copyWith({
    int? id,
    String? thumbnail,
    String? name,
    int? links,
    String? time,
    bool? isClassified,
    int? parentId,
    int? linksTotal,
  }) {
    return Folder(
      id: id ?? this.id,
      thumbnail: thumbnail ?? this.thumbnail,
      name: name ?? this.name,
      links: links ?? this.links,
      time: time ?? this.time,
      isClassified: isClassified ?? this.isClassified,
      parentId: parentId ?? this.parentId,
      linksTotal: linksTotal ?? this.linksTotal,
    );
  }
}
