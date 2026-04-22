import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/sync/merge_types.dart';

/// 순수 계산. IO 없음. 로컬 + 원격 스냅샷을 입력받아 머지된 folders + links 반환.
MergeResult computeMerge({
  required List<LocalFolder> localFolders,
  required List<LocalLink> localLinks,
  required List<Map<String, dynamic>> remoteFolders,
  required List<Map<String, dynamic>> remoteLinks,
  required DateTime mergeAt,
}) {
  return const MergeResult(
    folders: [],
    links: [],
    stats: MergeStats(
      foldersMerged: 0,
      foldersLocalOnly: 0,
      foldersRemoteOnly: 0,
      linksMerged: 0,
      linksLocalOnly: 0,
      linksRemoteOnly: 0,
    ),
  );
}
