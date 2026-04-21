import 'package:equatable/equatable.dart';

class LocalFolder extends Equatable {
  const LocalFolder({
    this.id,
    this.parentId,
    required this.name,
    this.thumbnail,
    this.isClassified = true,
    required this.createdAt,
    required this.updatedAt,
    this.linksCount,
  });

  final int? id;
  final int? parentId;
  final String name;
  final String? thumbnail;
  final bool isClassified;
  final String createdAt;
  final String updatedAt;
  final int? linksCount;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'thumbnail': thumbnail,
        'is_classified': isClassified ? 1 : 0,
        'parent_id': parentId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory LocalFolder.fromMap(Map<String, dynamic> map) => LocalFolder(
        id: map['id'] as int?,
        parentId: map['parent_id'] as int?,
        name: map['name'] as String,
        thumbnail: map['thumbnail'] as String?,
        isClassified: (map['is_classified'] as int?) == 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        linksCount: map['links_count'] as int?,
      );

  LocalFolder copyWith({
    int? id,
    Object? parentId = _sentinel,
    String? name,
    String? thumbnail,
    bool? isClassified,
    String? createdAt,
    String? updatedAt,
    int? linksCount,
  }) {
    return LocalFolder(
      id: id ?? this.id,
      parentId: identical(parentId, _sentinel) ? this.parentId : parentId as int?,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      isClassified: isClassified ?? this.isClassified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linksCount: linksCount ?? this.linksCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        parentId,
        name,
        thumbnail,
        isClassified,
        createdAt,
        updatedAt,
        linksCount,
      ];
}

const Object _sentinel = Object();
