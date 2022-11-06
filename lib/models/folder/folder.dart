import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.g.dart';

@JsonSerializable()
class Folder {
  Folder({this.id, this.imageUrl, this.private, this.name, this.linkCount});

  factory Folder.fromJson(Map<String, dynamic> json) =>
      _$FolderFromJson(json);

  Map<String, dynamic> toJson() => _$FolderToJson(this);
  
  int? id;
  String? imageUrl;
  bool? private;
  String? name;
  int? linkCount;
}
