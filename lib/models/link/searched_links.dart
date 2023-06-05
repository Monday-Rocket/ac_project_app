import 'package:ac_project_app/models/link/link.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'searched_links.g.dart';

@JsonSerializable()
class SearchedLinks extends Equatable {
  const SearchedLinks({
    this.pageNum,
    this.pageSize,
    this.totalCount,
    this.totalPage,
    this.contents,
  });

  factory SearchedLinks.fromJson(Map<String, dynamic> json) => _$SearchedLinksFromJson(json);

  Map<String, dynamic> toJson() => _$SearchedLinksToJson(this);

  @JsonKey(name: 'page_no')
  final int? pageNum;

  @JsonKey(name: 'page_size')
  final int? pageSize;

  @JsonKey(name: 'total_count')
  final int? totalCount;

  @JsonKey(name: 'total_page')
  final int? totalPage;

  final List<Link>? contents;

  bool hasMorePage() =>
      (pageNum ?? 0) < (totalPage ?? 0) - 1;

  @override
  List<Object?> get props => [pageNum, pageSize, totalCount, totalPage, contents];
}
