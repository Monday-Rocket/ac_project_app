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

  // 1. path_key 맵
  final localIdToPathKey = _buildLocalPathKeyMap(localFolders);
  final remoteClientIdToPathKey = _buildRemotePathKeyMap(remoteFolders);

  // 2. path_key → 로컬/원격 원본 그룹핑
  final localByKey = <String, LocalFolder>{};
  for (final f in localFolders) {
    final key = localIdToPathKey[f.id];
    if (key == null) continue;
    localByKey[key] = f;
  }
  final remoteByKey = <String, Map<String, dynamic>>{};
  for (final f in remoteFolders) {
    final clientId = f['client_id'] as int?;
    if (clientId == null) continue;
    final key = remoteClientIdToPathKey[clientId];
    if (key == null) continue;
    remoteByKey[key] = f;
  }

  // 출현 순서 보존: 로컬 먼저, 그 다음 원격 전용
  final orderedKeys = <String>[];
  final seen = <String>{};
  for (final key in localByKey.keys) {
    if (seen.add(key)) orderedKeys.add(key);
  }
  for (final key in remoteByKey.keys) {
    if (seen.add(key)) orderedKeys.add(key);
  }

  // 새 client_id 할당
  final pathKeyToNewId = <String, int>{
    for (var i = 0; i < orderedKeys.length; i++) orderedKeys[i]: i + 1,
  };

  // 3. 폴더 머지 + 필드 병합
  var foldersMerged = 0;
  var foldersLocalOnly = 0;
  var foldersRemoteOnly = 0;
  final localIdToNewId = <int, int>{};
  final remoteClientIdToNewId = <int, int>{};
  final mergedFolders = <LocalFolder>[];

  for (final key in orderedKeys) {
    final local = localByKey[key];
    final remote = remoteByKey[key];
    final newId = pathKeyToNewId[key]!;

    if (local != null && remote != null) {
      foldersMerged++;
      mergedFolders.add(_mergeFolder(
        newId: newId,
        local: local,
        remote: remote,
        mergeAtIso: mergeAtIso,
      ));
      localIdToNewId[local.id!] = newId;
      remoteClientIdToNewId[remote['client_id'] as int] = newId;
    } else if (local != null) {
      foldersLocalOnly++;
      mergedFolders.add(local.copyWith(id: newId, parentId: null));
      localIdToNewId[local.id!] = newId;
    } else if (remote != null) {
      foldersRemoteOnly++;
      mergedFolders.add(_folderFromRemote(newId: newId, remote: remote));
      remoteClientIdToNewId[remote['client_id'] as int] = newId;
    }
  }

  // 4. parent_id 복원 — path_key의 앞 구간을 부모 키로 사용
  // newId → pathKey 역방향 맵을 한 번만 구성해 O(1) 조회
  final newIdToPathKey = <int, String>{
    for (final e in pathKeyToNewId.entries) e.value: e.key,
  };
  final mergedFoldersWithParent = mergedFolders.map((f) {
    final key = f.id != null ? newIdToPathKey[f.id] : null;
    if (key == null) return f;
    final parentKey = _parentPathKey(key);
    if (parentKey == null) return f.copyWith(parentId: null);
    final parentNewId = pathKeyToNewId[parentKey];
    return f.copyWith(parentId: parentNewId);
  }).toList();

  // 5. 링크 머지
  final mergedLinks = <LocalLink>[];
  var linksMerged = 0;
  var linksLocalOnly = 0;
  var linksRemoteOnly = 0;
  var nextLinkId = 1;

  // serverId → clientId 역방향 맵을 한 번만 구성해 O(1) 조회
  final serverIdToClientId = <String, int>{
    for (final f in remoteFolders)
      if (f['client_id'] != null) (f['id'] as String): (f['client_id'] as int),
  };

  // 링크 키: (url, path_key)
  final localLinksByKey = <String, LocalLink>{};
  for (final l in localLinks) {
    final folderKey = localIdToPathKey[l.folderId];
    if (folderKey == null) continue;
    localLinksByKey['${l.url}$_pathSeparator$folderKey'] = l;
  }
  final remoteLinksByKey = <String, Map<String, dynamic>>{};
  for (final l in remoteLinks) {
    final folderServerId = l['folder_id'] as String?;
    if (folderServerId == null) continue;
    // folder_id(UUID) → client_id → path_key
    final folderClientId = serverIdToClientId[folderServerId];
    if (folderClientId == null) continue;
    final folderKey = remoteClientIdToPathKey[folderClientId];
    if (folderKey == null) continue;
    final url = l['url'] as String;
    remoteLinksByKey['$url$_pathSeparator$folderKey'] = l;
  }

  final linkOrder = <String>[];
  final linkSeen = <String>{};
  for (final k in localLinksByKey.keys) {
    if (linkSeen.add(k)) linkOrder.add(k);
  }
  for (final k in remoteLinksByKey.keys) {
    if (linkSeen.add(k)) linkOrder.add(k);
  }

  for (final compoundKey in linkOrder) {
    final local = localLinksByKey[compoundKey];
    final remote = remoteLinksByKey[compoundKey];
    // compound key = url + '\x00' + path_key
    // path_key 자체에 '\x00' 구분자가 포함될 수 있으므로 첫 번째 구분자 위치 이후를 사용
    final separatorIdx = compoundKey.indexOf(_pathSeparator);
    final folderPathKey = compoundKey.substring(separatorIdx + 1);
    final newFolderId = pathKeyToNewId[folderPathKey];
    if (newFolderId == null) continue;

    if (local != null && remote != null) {
      linksMerged++;
      mergedLinks.add(_mergeLink(
        newId: nextLinkId++,
        newFolderId: newFolderId,
        local: local,
        remote: remote,
        mergeAtIso: mergeAtIso,
      ));
    } else if (local != null) {
      linksLocalOnly++;
      mergedLinks.add(local.copyWith(
        id: nextLinkId++,
        folderId: newFolderId,
      ));
    } else if (remote != null) {
      linksRemoteOnly++;
      mergedLinks.add(_linkFromRemote(
        newId: nextLinkId++,
        newFolderId: newFolderId,
        remote: remote,
      ));
    }
  }

  return MergeResult(
    folders: mergedFoldersWithParent,
    links: mergedLinks,
    stats: MergeStats(
      foldersMerged: foldersMerged,
      foldersLocalOnly: foldersLocalOnly,
      foldersRemoteOnly: foldersRemoteOnly,
      linksMerged: linksMerged,
      linksLocalOnly: linksLocalOnly,
      linksRemoteOnly: linksRemoteOnly,
    ),
  );
}

LocalFolder _mergeFolder({
  required int newId,
  required LocalFolder local,
  required Map<String, dynamic> remote,
  required String mergeAtIso,
}) {
  final localUpdated = DateTime.parse(local.updatedAt);
  final remoteUpdated = DateTime.parse(remote['updated_at'] as String);
  final newer = localUpdated.isAfter(remoteUpdated) ? 'local' : 'remote';

  String? pickString(String? a, String? b) {
    final aEmpty = a == null || a.isEmpty;
    final bEmpty = b == null || b.isEmpty;
    if (aEmpty && bEmpty) return null;
    if (aEmpty) return b;
    if (bEmpty) return a;
    return newer == 'local' ? a : b;
  }

  final localCreated = DateTime.parse(local.createdAt);
  final remoteCreated = DateTime.parse(remote['created_at'] as String);
  final earlierCreated = localCreated.isBefore(remoteCreated)
      ? local.createdAt
      : remote['created_at'] as String;

  final remoteIsClassified = (remote['is_classified'] as bool?) ?? true;

  return LocalFolder(
    id: newId,
    parentId: null,
    name: local.name,
    thumbnail: pickString(local.thumbnail, remote['thumbnail'] as String?),
    isClassified: local.isClassified || remoteIsClassified,
    createdAt: earlierCreated,
    updatedAt: mergeAtIso,
  );
}

LocalFolder _folderFromRemote({
  required int newId,
  required Map<String, dynamic> remote,
}) {
  return LocalFolder(
    id: newId,
    parentId: null,
    name: remote['name'] as String,
    thumbnail: remote['thumbnail'] as String?,
    isClassified: (remote['is_classified'] as bool?) ?? true,
    createdAt: remote['created_at'] as String,
    updatedAt: remote['updated_at'] as String,
  );
}

LocalLink _mergeLink({
  required int newId,
  required int newFolderId,
  required LocalLink local,
  required Map<String, dynamic> remote,
  required String mergeAtIso,
}) {
  final localUpdated = DateTime.parse(local.updatedAt);
  final remoteUpdated = DateTime.parse(remote['updated_at'] as String);
  final newer = localUpdated.isAfter(remoteUpdated) ? 'local' : 'remote';

  String? pickString(String? a, String? b) {
    final aEmpty = a == null || a.isEmpty;
    final bEmpty = b == null || b.isEmpty;
    if (aEmpty && bEmpty) return null;
    if (aEmpty) return b;
    if (bEmpty) return a;
    return newer == 'local' ? a : b;
  }

  final localCreated = DateTime.parse(local.createdAt);
  final remoteCreated = DateTime.parse(remote['created_at'] as String);
  final earlierCreated = localCreated.isBefore(remoteCreated)
      ? local.createdAt
      : remote['created_at'] as String;

  return LocalLink(
    id: newId,
    folderId: newFolderId,
    url: local.url, // 로컬 원본
    title: pickString(local.title, remote['title'] as String?),
    image: pickString(local.image, remote['image'] as String?),
    describe: pickString(local.describe, remote['describe'] as String?),
    inflowType: pickString(local.inflowType, remote['inflow_type'] as String?),
    createdAt: earlierCreated,
    updatedAt: mergeAtIso,
  );
}

LocalLink _linkFromRemote({
  required int newId,
  required int newFolderId,
  required Map<String, dynamic> remote,
}) {
  return LocalLink(
    id: newId,
    folderId: newFolderId,
    url: remote['url'] as String,
    title: remote['title'] as String?,
    image: remote['image'] as String?,
    describe: remote['describe'] as String?,
    inflowType: remote['inflow_type'] as String?,
    createdAt: remote['created_at'] as String,
    updatedAt: remote['updated_at'] as String,
  );
}

String? _parentPathKey(String key) {
  if (key == _unclassifiedPathKey) return null;
  final idx = key.lastIndexOf(_pathSeparator);
  if (idx < 0) return null;
  return key.substring(0, idx);
}

/// 로컬 폴더의 id → path_key 맵
Map<int, String> _buildLocalPathKeyMap(List<LocalFolder> folders) {
  final byId = {
    for (final f in folders)
      if (f.id != null) f.id!: f
  };
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
Map<int, String> _buildRemotePathKeyMap(
    List<Map<String, dynamic>> remoteFolders) {
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
