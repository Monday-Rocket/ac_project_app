import 'package:equatable/equatable.dart';

class LocalLink extends Equatable {
  const LocalLink({
    this.id,
    required this.folderId,
    required this.url,
    this.title,
    this.image,
    this.describe,
    this.inflowType,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int folderId;
  final String url;
  final String? title;
  final String? image;
  final String? describe;
  final String? inflowType;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'folder_id': folderId,
        'url': url,
        'title': title,
        'image': image,
        'describe': describe,
        'inflow_type': inflowType,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory LocalLink.fromMap(Map<String, dynamic> map) => LocalLink(
        id: map['id'] as int?,
        folderId: map['folder_id'] as int,
        url: map['url'] as String,
        title: map['title'] as String?,
        image: map['image'] as String?,
        describe: map['describe'] as String?,
        inflowType: map['inflow_type'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  LocalLink copyWith({
    int? id,
    int? folderId,
    String? url,
    String? title,
    String? image,
    String? describe,
    String? inflowType,
    String? createdAt,
    String? updatedAt,
  }) {
    return LocalLink(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      url: url ?? this.url,
      title: title ?? this.title,
      image: image ?? this.image,
      describe: describe ?? this.describe,
      inflowType: inflowType ?? this.inflowType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, folderId, url, title, image, describe, inflowType, createdAt, updatedAt];
}
