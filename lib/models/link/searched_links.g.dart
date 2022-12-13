// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'searched_links.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchedLinks _$SearchedLinksFromJson(Map<String, dynamic> json) =>
    SearchedLinks(
      pageNum: json['page_no'] as int?,
      pageSize: json['page_size'] as int?,
      totalCount: json['total_count'] as int?,
      totalPage: json['total_page'] as int?,
      contents: (json['contents'] as List<dynamic>?)
          ?.map((e) => Link.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchedLinksToJson(SearchedLinks instance) =>
    <String, dynamic>{
      'page_no': instance.pageNum,
      'page_size': instance.pageSize,
      'total_count': instance.totalCount,
      'total_page': instance.totalPage,
      'contents': instance.contents,
    };
