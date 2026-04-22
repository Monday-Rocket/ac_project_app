import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:equatable/equatable.dart';

abstract class LinkListState extends Equatable {}

class LinkListInitialState extends LinkListState {
  @override
  List<Object> get props => [];
}

class LinkListLoadingState extends LinkListState {
  @override
  List<Object> get props => [];
}

class LinkListLoadedState extends LinkListState {
  LinkListLoadedState(
    this.links,
    this.totalCount, {
    this.breadcrumb = const [],
    this.childFolders = const [],
  });

  final List<Link> links;
  final int totalCount;

  /// 루트 → 현재 폴더까지의 경로. 미분류거나 로드 실패 시 빈 리스트.
  final List<Folder> breadcrumb;

  /// 현재 폴더의 직계 하위 폴더. 재귀 링크 카운트 포함.
  final List<Folder> childFolders;

  @override
  List<Object> get props => [links, totalCount, breadcrumb, childFolders];
}

class LinkListErrorState extends LinkListState {
  LinkListErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
