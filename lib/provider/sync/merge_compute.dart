import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/sync/merge_types.dart';

const String _unclassifiedPathKey = '__UNCLASSIFIED__';
const String _pathSeparator = '\x00';

/// 순수 계산. IO 없음. 로컬 + 원격 스냅샷을 입력받아 머지된 folders + links 반환.
MergeResult computeMerge({
  required List<LocalFolder> localFolders,
  required List<LocalLink> localLinks,
  required List<Map<String, dynamic>> remoteFolders,
  required List<Map<String, dynamic>> remoteLinks,
  required DateTime mergeAt,
}) {
  final mergeAtIso = mergeAt.toUtc().toIso8601String();

  // 1. path_key 맵 구축
  final localIdToPathKey = _buildLocalPathKeyMap(localFolders);
  final remoteClientIdToPathKey = _buildRemotePathKeyMap(remoteFolders);

  // 2. 폴더 머지 (이번 task에서는 로컬 전용 경로만 처리)
  final pathKeys = <String>{};
  final orderedPathKeys = <String>[];
  for (final f in localFolders) {
    final key = localIdToPathKey[f.id];
    if (key == null) continue;
    if (pathKeys.add(key)) orderedPathKeys.add(key);
  }

  // 새 client_id 할당 (1부터 순차)
  final pathKeyToNewId = <String, int>{};
  var nextFolderId = 1;
  for (final key in orderedPathKeys) {
    pathKeyToNewId[key] = nextFolderId++;
  }

  // 폴더 재구성
  final mergedFolders = <LocalFolder>[];
  final localIdToNewId = <int, int>{};
  for (final f in localFolders) {
    final key = localIdToPathKey[f.id];
    if (key == null) continue;
    final newId = pathKeyToNewId[key]!;
    localIdToNewId[f.id!] = newId;
    mergedFolders.add(f.copyWith(
      id: newId,
      parentId: null, // parent 매핑은 3단계에서
    ));
  }

  // 3. parent_id 복원 (로컬 전용이므로 기존 로컬 parent 관계를 새 id로 치환)
  final mergedFoldersWithParent = mergedFolders.map((f) {
    final originalLocal = localFolders.firstWhere((lf) => localIdToNewId[lf.id] == f.id);
    final oldParentId = originalLocal.parentId;
    if (oldParentId == null) return f;
    final newParentId = localIdToNewId[oldParentId];
    return f.copyWith(parentId: newParentId);
  }).toList();

  // 4. 링크 머지 (로컬 전용)
  final mergedLinks = <LocalLink>[];
  var nextLinkId = 1;
  for (final l in localLinks) {
    final newFolderId = localIdToNewId[l.folderId];
    if (newFolderId == null) continue; // 부모 폴더가 사라졌으면 스킵
    mergedLinks.add(l.copyWith(
      id: nextLinkId++,
      folderId: newFolderId,
    ));
  }

  return MergeResult(
    folders: mergedFoldersWithParent,
    links: mergedLinks,
    stats: MergeStats(
      foldersMerged: 0,
      foldersLocalOnly: mergedFoldersWithParent.length,
      foldersRemoteOnly: 0,
      linksMerged: 0,
      linksLocalOnly: mergedLinks.length,
      linksRemoteOnly: 0,
    ),
  );
}

/// 로컬 폴더의 id → path_key 맵
Map<int, String> _buildLocalPathKeyMap(List<LocalFolder> folders) {
  final byId = {for (final f in folders) if (f.id != null) f.id!: f};
  final result = <int, String>{};
  for (final f in folders) {
    if (f.id == null) continue;
    result[f.id!] = _computeLocalPathKey(f, byId);
  }
  return result;
}

String _computeLocalPathKey(
  LocalFolder folder,
  Map<int, LocalFolder> byId,
) {
  if (!folder.isClassified) return _unclassifiedPathKey;
  final segments = <String>[folder.name];
  var parentId = folder.parentId;
  final visited = <int>{folder.id!};
  while (parentId != null) {
    if (!visited.add(parentId)) break; // 순환 방지
    final parent = byId[parentId];
    if (parent == null) break;
    segments.insert(0, parent.name);
    parentId = parent.parentId;
  }
  return segments.join(_pathSeparator);
}

/// 원격 폴더(Map)의 client_id → path_key 맵
Map<int, String> _buildRemotePathKeyMap(List<Map<String, dynamic>> remoteFolders) {
  final byServerId = {
    for (final f in remoteFolders) (f['id'] as String): f,
  };
  final result = <int, String>{};
  for (final f in remoteFolders) {
    final clientId = f['client_id'] as int?;
    if (clientId == null) continue;
    result[clientId] = _computeRemotePathKey(f, byServerId);
  }
  return result;
}

String _computeRemotePathKey(
  Map<String, dynamic> folder,
  Map<String, Map<String, dynamic>> byServerId,
) {
  final isClassified = (folder['is_classified'] as bool?) ?? true;
  if (!isClassified) return _unclassifiedPathKey;
  final segments = <String>[folder['name'] as String];
  var parentServerId = folder['parent_id'] as String?;
  final visited = <String>{folder['id'] as String};
  while (parentServerId != null) {
    if (!visited.add(parentServerId)) break;
    final parent = byServerId[parentServerId];
    if (parent == null) break;
    segments.insert(0, parent['name'] as String);
    parentServerId = parent['parent_id'] as String?;
  }
  return segments.join(_pathSeparator);
}
