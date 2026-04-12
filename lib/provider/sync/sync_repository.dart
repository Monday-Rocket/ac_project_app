import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncRepository {
  final SupabaseClient _client;
  final LocalFolderRepository _folderRepo;
  final LocalLinkRepository _linkRepo;

  static const _folderMapKey = 'lp_sync_folder_map';
  static const _linkMapKey = 'lp_sync_link_map';
  static const _lastSyncKey = 'lp_sync_last_at';

  SyncRepository({
    required LocalFolderRepository folderRepo,
    required LocalLinkRepository linkRepo,
    SupabaseClient? client,
  })  : _folderRepo = folderRepo,
        _linkRepo = linkRepo,
        _client = client ?? Supabase.instance.client;

  // ── ID 매핑 관리 ──

  Future<Map<int, String>> _getFolderMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_folderMapKey) ?? [];
    final map = <int, String>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[int.parse(parts[0])] = parts[1];
      }
    }
    return map;
  }

  Future<void> _setFolderMap(Map<int, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = map.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_folderMapKey, raw);
  }

  Future<Map<int, String>> _getLinkMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_linkMapKey) ?? [];
    final map = <int, String>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[int.parse(parts[0])] = parts[1];
      }
    }
    return map;
  }

  Future<void> _setLinkMap(Map<int, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = map.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_linkMapKey, raw);
  }

  Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  Future<void> _setLastSyncAt(String at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, at);
  }

  Future<bool> isSyncSetup() async {
    final map = await _getFolderMap();
    return map.isNotEmpty;
  }

  // ── 초기 업로드 ──

  Future<void> initialUpload() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final folders = await _folderRepo.getAllFolders();
    final folderMap = <int, String>{};

    // 폴더 업로드
    for (final folder in folders) {
      final data = await _client.from('folders').insert({
        'user_id': user.id,
        'client_id': folder.id,
        'name': folder.name,
        'thumbnail': folder.thumbnail,
        'is_classified': folder.isClassified,
        'created_at': folder.createdAt,
        'updated_at': folder.updatedAt,
      }).select('id').single();

      folderMap[folder.id!] = data['id'] as String;
    }

    await _setFolderMap(folderMap);

    // 링크 업로드 (50개씩 배치)
    final linkMap = <int, String>{};
    final allLinks = await _linkRepo.getAllLinks();

    for (var i = 0; i < allLinks.length; i += 50) {
      final batch = allLinks.skip(i).take(50).toList();
      final rows = batch.map((link) => {
        'user_id': user.id,
        'client_id': link.id,
        'folder_id': folderMap[link.folderId],
        'url': link.url,
        'title': link.title,
        'image': link.image,
        'describe': link.describe,
        'inflow_type': link.inflowType,
        'created_at': link.createdAt,
        'updated_at': link.updatedAt,
      }).toList();

      final data = await _client
          .from('links')
          .insert(rows)
          .select('id, client_id');

      for (final row in data) {
        linkMap[row['client_id'] as int] = row['id'] as String;
      }
    }

    await _setLinkMap(linkMap);
    await _setLastSyncAt(DateTime.now().toUtc().toIso8601String());
  }

  // ── 증분 동기화 ──

  Future<void> incrementalSync() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final lastSync = await getLastSyncAt();
    final syncStartedAt = DateTime.now().toUtc().toIso8601String();

    final folderMap = await _getFolderMap();
    final linkMap = await _getLinkMap();

    await _pullFolders(user.id, lastSync, folderMap);
    await _pullLinks(user.id, lastSync, folderMap, linkMap);
    await _pushFolders(user.id, lastSync, folderMap);
    await _pushLinks(user.id, lastSync, folderMap, linkMap);

    await _setFolderMap(folderMap);
    await _setLinkMap(linkMap);
    await _setLastSyncAt(syncStartedAt);
  }

  // ── Pull: 서버 → 로컬 ──

  Future<void> _pullFolders(
    String userId,
    String? lastSync,
    Map<int, String> folderMap,
  ) async {
    var query = _client.from('folders').select().eq('user_id', userId);
    if (lastSync != null) query = query.gt('updated_at', lastSync);

    final serverFolders = await query;
    final reverseMap = _invertMap(folderMap);

    for (final sf in serverFolders) {
      final uuid = sf['id'] as String;
      final localId = reverseMap[uuid];

      if (sf['deleted_at'] != null) {
        if (localId != null) {
          await _folderRepo.deleteFolder(localId);
        }
        continue;
      }

      if (localId != null) {
        final local = await _folderRepo.getFolderById(localId);
        if (local != null && (sf['updated_at'] as String).compareTo(local.updatedAt) > 0) {
          await _folderRepo.updateFolder(local.copyWith(
            name: sf['name'] as String,
            thumbnail: sf['thumbnail'] as String?,
            isClassified: sf['is_classified'] as bool,
          ));
        }
      } else {
        final now = DateTime.now().toUtc().toIso8601String();
        final created = await _folderRepo.createFolder(LocalFolder(
          name: sf['name'] as String,
          thumbnail: sf['thumbnail'] as String?,
          isClassified: sf['is_classified'] as bool,
          createdAt: sf['created_at'] as String? ?? now,
          updatedAt: sf['updated_at'] as String? ?? now,
        ));
        folderMap[created] = uuid;
      }
    }
  }

  Future<void> _pullLinks(
    String userId,
    String? lastSync,
    Map<int, String> folderMap,
    Map<int, String> linkMap,
  ) async {
    var query = _client.from('links').select().eq('user_id', userId);
    if (lastSync != null) query = query.gt('updated_at', lastSync);

    final serverLinks = await query;
    final reverseFolder = _invertMap(folderMap);
    final reverseLink = _invertMap(linkMap);

    for (final sl in serverLinks) {
      final uuid = sl['id'] as String;
      final localId = reverseLink[uuid];
      final folderUuid = sl['folder_id'] as String;
      final localFolderId = reverseFolder[folderUuid];

      if (sl['deleted_at'] != null) {
        if (localId != null) await _linkRepo.deleteLink(localId);
        continue;
      }

      if (localFolderId == null) continue;

      if (localId != null) {
        final local = await _linkRepo.getLinkById(localId);
        if (local != null && (sl['updated_at'] as String).compareTo(local.updatedAt) > 0) {
          await _linkRepo.updateLink(local.copyWith(
            folderId: localFolderId,
            url: sl['url'] as String,
            title: sl['title'] as String?,
            image: sl['image'] as String?,
            describe: sl['describe'] as String?,
          ));
        }
      } else {
        final now = DateTime.now().toUtc().toIso8601String();
        final created = await _linkRepo.createLink(LocalLink(
          folderId: localFolderId,
          url: sl['url'] as String,
          title: sl['title'] as String?,
          image: sl['image'] as String?,
          describe: sl['describe'] as String?,
          inflowType: sl['inflow_type'] as String?,
          createdAt: sl['created_at'] as String? ?? now,
          updatedAt: sl['updated_at'] as String? ?? now,
        ));
        linkMap[created] = uuid;
      }
    }
  }

  // ── Push: 로컬 → 서버 ──

  Future<void> _pushFolders(
    String userId,
    String? lastSync,
    Map<int, String> folderMap,
  ) async {
    final folders = await _folderRepo.getAllFolders();

    for (final folder in folders) {
      final uuid = folderMap[folder.id];

      if (uuid == null) {
        final data = await _client.from('folders').insert({
          'user_id': userId,
          'client_id': folder.id,
          'name': folder.name,
          'thumbnail': folder.thumbnail,
          'is_classified': folder.isClassified,
          'created_at': folder.createdAt,
          'updated_at': folder.updatedAt,
        }).select('id').single();

        folderMap[folder.id!] = data['id'] as String;
      } else if (lastSync == null || folder.updatedAt.compareTo(lastSync) > 0) {
        final serverData = await _client
            .from('folders')
            .select('updated_at')
            .eq('id', uuid)
            .single();

        if (folder.updatedAt.compareTo(serverData['updated_at'] as String) > 0) {
          await _client.from('folders').update({
            'name': folder.name,
            'thumbnail': folder.thumbnail,
            'is_classified': folder.isClassified,
            'updated_at': folder.updatedAt,
          }).eq('id', uuid);
        }
      }
    }
  }

  Future<void> _pushLinks(
    String userId,
    String? lastSync,
    Map<int, String> folderMap,
    Map<int, String> linkMap,
  ) async {
    final links = await _linkRepo.getAllLinks();

    for (final link in links) {
      final uuid = linkMap[link.id];
      final folderUuid = folderMap[link.folderId];
      if (folderUuid == null) continue;

      if (uuid == null) {
        final data = await _client.from('links').insert({
          'user_id': userId,
          'client_id': link.id,
          'folder_id': folderUuid,
          'url': link.url,
          'title': link.title,
          'image': link.image,
          'describe': link.describe,
          'inflow_type': link.inflowType,
          'created_at': link.createdAt,
          'updated_at': link.updatedAt,
        }).select('id').single();

        linkMap[link.id!] = data['id'] as String;
      } else if (lastSync == null || link.updatedAt.compareTo(lastSync) > 0) {
        final serverData = await _client
            .from('links')
            .select('updated_at')
            .eq('id', uuid)
            .single();

        if (link.updatedAt.compareTo(serverData['updated_at'] as String) > 0) {
          await _client.from('links').update({
            'folder_id': folderUuid,
            'url': link.url,
            'title': link.title,
            'image': link.image,
            'describe': link.describe,
            'updated_at': link.updatedAt,
          }).eq('id', uuid);
        }
      }
    }
  }

  // ── 유틸 ──

  Map<String, int> _invertMap(Map<int, String> map) {
    return {for (final e in map.entries) e.value: e.key};
  }

  Future<void> clearSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderMapKey);
    await prefs.remove(_linkMapKey);
    await prefs.remove(_lastSyncKey);
  }
}
