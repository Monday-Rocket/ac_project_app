import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:equatable/equatable.dart';

/// 머지 계산 결과. 새 client_id, parent_id, folder_id 매핑이 모두 적용된 상태.
class MergeResult extends Equatable {
  const MergeResult({
    required this.folders,
    required this.links,
    required this.stats,
  });

  final List<LocalFolder> folders;
  final List<LocalLink> links;
  final MergeStats stats;

  @override
  List<Object?> get props => [folders, links, stats];
}

/// 머지 통계. 로그/진단용.
class MergeStats extends Equatable {
  const MergeStats({
    required this.foldersMerged,
    required this.foldersLocalOnly,
    required this.foldersRemoteOnly,
    required this.linksMerged,
    required this.linksLocalOnly,
    required this.linksRemoteOnly,
  });

  final int foldersMerged;
  final int foldersLocalOnly;
  final int foldersRemoteOnly;
  final int linksMerged;
  final int linksLocalOnly;
  final int linksRemoteOnly;

  int get totalFolders => foldersMerged + foldersLocalOnly + foldersRemoteOnly;
  int get totalLinks => linksMerged + linksLocalOnly + linksRemoteOnly;

  @override
  List<Object?> get props => [
        foldersMerged,
        foldersLocalOnly,
        foldersRemoteOnly,
        linksMerged,
        linksLocalOnly,
        linksRemoteOnly,
      ];

  @override
  String toString() =>
      'MergeStats(folders: $foldersMerged merged / $foldersLocalOnly local-only / $foldersRemoteOnly remote-only, '
      'links: $linksMerged merged / $linksLocalOnly local-only / $linksRemoteOnly remote-only)';
}
