import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.g.dart';

@JsonSerializable()
class Folder {
  Folder(
      {this.id,
      this.thumbnail,
      this.visible,
      this.name,
      this.links,
      this.time});

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  Map<String, dynamic> toJson() => _$FolderToJson(this);

  int? id;
  String? thumbnail = '';
  bool? visible = true;
  String? name;
  int? links = 0;

  @JsonKey(name: 'created_date_time')
  String? time;
}
