import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.g.dart';

@JsonSerializable()
class Folder extends Equatable {
  Folder({
    this.id,
    this.thumbnail,
    this.visible,
    this.name,
    this.links,
    this.time,
  });

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  Map<String, dynamic> toJson() => _$FolderToJson(this);

  int? id;
  String? thumbnail = '';
  bool? visible = true;
  String? name;
  int? links = 0;

  @JsonKey(name: 'created_date_time')
  String? time;

  bool? isClassified = true;

  static bool containsNameFromFolderList(List<Folder> folders, String? value) {
    return folders.map((folder) => folder.name).toList().contains(value ?? '');
  }

  @override
  List<Object?> get props => [id, thumbnail, visible, name, links];


  Folder copyWith({
    int? id,
    String? thumbnail,
    bool? visible,
    String? name,
    int? links,
    String? time,
    bool? isClassified,
  }) {
    return Folder(
      id: id ?? this.id,
      thumbnail: thumbnail ?? this.thumbnail,
      visible: visible ?? this.visible,
      name: name ?? this.name,
      links: links ?? this.links,
      time: time ?? this.time,
    );
  }
}
