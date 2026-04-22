import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/recent_folders_repository.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/provider/sync/merge_compute.dart';
import 'package:ac_project_app/provider/sync/merge_types.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pro 백업/복구 + 원격 CRUD 쓰기 전담 Repository.
///
/// 정책 요약 (로드맵 §4):
/// - 로컬 SQLite = 진실의 원천.
/// - Pro 유저: CRUD 시 로컬 + 원격에 fire-and-forget 동시 쓰기.
///   원격 쓰기 실패 시 `lp_remote_dirty` 플래그 ON → 다음 기회에 full replace 로 보정.
/// - 백업은 full replace 트랜잭션 (기존 원격 folders/links 전부 DELETE + 로컬 전체 INSERT).
/// - 복구는 원격 메모리 다운로드 → 로컬 SQLite 트랜잭션 교체 + sqlite_sequence 보정.
/// - Pro → Free 전환 시 원격 전체 삭제(purgeRemote).
/// - 삭제는 hard delete 로 통일.
/// - `_isBackingUp` 플래그로 중복 실행 방지.
class SyncRepository {
  SyncRepository({
    required LocalFolderRepository folderRepo,
    required LocalLinkRepository linkRepo,
    DatabaseHelper? databaseHelper,
    SupabaseClient? client,
  })  : _folderRepo = folderRepo,
        _linkRepo = linkRepo,
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _client = client ?? Supabase.instance.client;

  final LocalFolderRepository _folderRepo;
  final LocalLinkRepository _linkRepo;
  final DatabaseHelper _databaseHelper;
  final SupabaseClient _client;

  static const _kLastBackupAt = 'lp_last_backup_at';
  static const _kRemoteDirty = 'lp_remote_dirty';
  static const _kDirtySince = 'lp_remote_dirty_since';

  bool _isBackingUp = false;
  bool _isMerging = false;

  String? _requireUserId() => _client.auth.currentUser?.id;

  // ── 플래그/메타 ───────────────────────────────────────────────────────

  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastBackupAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _setLastBackupAtNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackupAt, DateTime.now().toIso8601String());
  }

  Future<bool> isDirty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemoteDirty) ?? false;
  }

  /// dirty 상태가 언제부터 지속되고 있는지. dirty 해제되면 null.
  Future<DateTime?> getDirtySince() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDirtySince);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _setDirty(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getBool(_kRemoteDirty) ?? false;
    await prefs.setBool(_kRemoteDirty, value);
    if (value && !prev) {
      // false → true 전환 시점에만 시작 시각 기록 (기존 dirty 이어지면 유지)
      await prefs.setString(_kDirtySince, DateTime.now().toIso8601String());
    } else if (!value) {
      await prefs.remove(_kDirtySince);
    }
  }

  // ── 원격 쓰기 래퍼 ────────────────────────────────────────────────────

  /// 모든 원격 쓰기 경로는 이 래퍼를 경유.
  /// - 요청 전 dirty=true (optimistic: 앱 강제종료 시에도 다음에 보정됨)
  /// - 성공 시 dirty=false
  /// - 실패 시 dirty 유지, 예외는 로그만 남기고 삼킴 (fire-and-forget)
  Future<void> remoteWrite(Future<void> Function() operation) async {
    await _setDirty(true);
    try {
      await operation();
      await _setDirty(false);
    } catch (e) {
      Log.e('SyncRepository.remoteWrite failed: $e');
    }
  }

  // ── 개별 upsert/delete ───────────────────────────────────────────────

  Future<void> upsertFolderRemote(LocalFolder folder) async {
    final userId = _requireUserId();
    if (userId == null || folder.id == null) return;
    await remoteWrite(() async {
      await _client.from('folders').upsert({
        'user_id': userId,
        'client_id': folder.id,
        'parent_id': null, // 로컬 parent_id는 int, 원격은 UUID. 원격 parent 매핑은 full replace 경로에서만 정확 설정.
        'name': folder.name,
        'thumbnail': folder.thumbnail,
        'is_classified': folder.isClassified,
        'created_at': folder.createdAt,
        'updated_at': folder.updatedAt,
      }, onConflict: 'user_id,client_id');
    });
  }

  Future<void> upsertLinkRemote(LocalLink link) async {
    final userId = _requireUserId();
    if (userId == null || link.id == null) return;
    final folderServerId = await _resolveRemoteFolderId(userId, link.folderId);
    if (folderServerId == null) {
      // 부모 폴더가 아직 원격에 없으면 dirty만 세팅해두고 다음 full replace에서 해결
      await _setDirty(true);
      return;
    }
    await remoteWrite(() async {
      await _client.from('links').upsert({
        'user_id': userId,
        'client_id': link.id,
        'folder_id': folderServerId,
        'url': link.url,
        'title': link.title,
        'image': link.image,
        'describe': link.describe,
        'inflow_type': link.inflowType,
        'created_at': link.createdAt,
        'updated_at': link.updatedAt,
      }, onConflict: 'user_id,client_id');
    });
  }

  Future<void> deleteFolderRemote(int localFolderId) async {
    final userId = _requireUserId();
    if (userId == null) return;
    await remoteWrite(() async {
      await _client
          .from('folders')
          .delete()
          .match({'user_id': userId, 'client_id': localFolderId});
    });
  }

  Future<void> deleteLinkRemote(int localLinkId) async {
    final userId = _requireUserId();
    if (userId == null) return;
    await remoteWrite(() async {
      await _client
          .from('links')
          .delete()
          .match({'user_id': userId, 'client_id': localLinkId});
    });
  }

  Future<String?> _resolveRemoteFolderId(String userId, int localFolderId) async {
    final rows = await _client
        .from('folders')
        .select('id')
        .match({'user_id': userId, 'client_id': localFolderId})
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  // ── 백업 (full replace) ──────────────────────────────────────────────

  /// 원격 원본을 로컬 전체 상태로 교체.
  /// Pro 전환 시 / dirty 보정 시 / 수동 백업 시 동일하게 사용.
  /// 원격 folders, links 전부 DELETE → 로컬 전체 INSERT.
  /// parent_id 매핑을 위해 folders 를 먼저 모두 INSERT 해 client_id ↔ id 맵을 확보.
  Future<bool> backupToRemote() async {
    if (_isBackingUp) return false;
    final userId = _requireUserId();
    if (userId == null) return false;

    _isBackingUp = true;
    try {
      final folders = await _folderRepo.getAllFolders();
      final links = await _linkRepo.getAllLinks();

      // 1) 원격 초기화
      await _client.from('links').delete().match({'user_id': userId});
      await _client.from('folders').delete().match({'user_id': userId});

      // 2) 폴더 INSERT (parent_id 없이)
      final folderRows = folders
          .where((f) => f.id != null)
          .map((f) => {
                'user_id': userId,
                'client_id': f.id,
                'name': f.name,
                'thumbnail': f.thumbnail,
                'is_classified': f.isClassified,
                'created_at': f.createdAt,
                'updated_at': f.updatedAt,
              })
          .toList();
      if (folderRows.isNotEmpty) {
        await _client.from('folders').insert(folderRows);
      }

      // 3) folders의 client_id → 원격 id 맵 확보 (parent_id 2차 UPDATE 용)
      final folderRemote = await _client
          .from('folders')
          .select('id, client_id')
          .match({'user_id': userId});
      final clientToServerFolderId = <int, String>{
        for (final row in folderRemote)
          (row['client_id'] as int): (row['id'] as String),
      };

      // 4) parent_id 세팅 (로컬 parent_id(int) → 원격 parent uuid)
      for (final f in folders) {
        if (f.id == null || f.parentId == null) continue;
        final parentRemote = clientToServerFolderId[f.parentId!];
        if (parentRemote == null) continue;
        await _client
            .from('folders')
            .update({'parent_id': parentRemote})
            .match({'user_id': userId, 'client_id': f.id!});
      }

      // 5) 링크 INSERT (folder_id 매핑)
      final linkRows = <Map<String, dynamic>>[];
      for (final l in links) {
        if (l.id == null) continue;
        final folderRemoteId = clientToServerFolderId[l.folderId];
        if (folderRemoteId == null) continue;
        linkRows.add({
          'user_id': userId,
          'client_id': l.id,
          'folder_id': folderRemoteId,
          'url': l.url,
          'title': l.title,
          'image': l.image,
          'describe': l.describe,
          'inflow_type': l.inflowType,
          'created_at': l.createdAt,
          'updated_at': l.updatedAt,
        });
      }
      if (linkRows.isNotEmpty) {
        await _client.from('links').insert(linkRows);
      }

      await _setLastBackupAtNow();
      await _setDirty(false);
      Log.i('backupToRemote ok: ${folders.length} folders, ${links.length} links');
      return true;
    } catch (e) {
      Log.e('backupToRemote failed: $e');
      return false;
    } finally {
      _isBackingUp = false;
    }
  }

  /// Pro 자동 복구 팝업 조건 체크용.
  Future<bool> hasRemoteBackup() async {
    final userId = _requireUserId();
    if (userId == null) return false;
    final rows = await _client
        .from('folders')
        .select('id')
        .match({'user_id': userId})
        .limit(1);
    return rows.isNotEmpty;
  }

  // ── 복구 ──────────────────────────────────────────────────────────────

  /// 원격 → 로컬 전체 복구.
  /// 1) 원격 folders/links 전체 다운로드 (메모리)
  /// 2) 성공 시 로컬 SQLite 트랜잭션: 기존 데이터 삭제 + 새 데이터 삽입
  /// 3) sqlite_sequence 보정 (다음 insert id 충돌 방지)
  Future<void> restoreFromRemote() async {
    final userId = _requireUserId();
    if (userId == null) return;

    // 1) 원격 다운로드
    final remoteFolders = await _client
        .from('folders')
        .select()
        .match({'user_id': userId});
    final remoteLinks = await _client
        .from('links')
        .select()
        .match({'user_id': userId});

    // 원격 parent uuid → client_id 역매핑을 위해 server_id → client_id 맵 준비
    final serverIdToClient = <String, int>{
      for (final f in remoteFolders)
        (f['id'] as String): (f['client_id'] as int),
    };

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('link');
      await txn.delete('folder');

      for (final f in remoteFolders) {
        final clientId = f['client_id'] as int;
        final parentServer = f['parent_id'] as String?;
        final parentClient =
            parentServer != null ? serverIdToClient[parentServer] : null;
        await txn.insert('folder', {
          'id': clientId,
          'name': f['name'] as String,
          'thumbnail': f['thumbnail'] as String?,
          'is_classified': (f['is_classified'] as bool) ? 1 : 0,
          'parent_id': parentClient,
          'created_at': f['created_at'] as String,
          'updated_at': f['updated_at'] as String,
        });
      }

      for (final l in remoteLinks) {
        final clientId = l['client_id'] as int;
        final folderServer = l['folder_id'] as String;
        final folderClient = serverIdToClient[folderServer];
        if (folderClient == null) continue;
        await txn.insert('link', {
          'id': clientId,
          'folder_id': folderClient,
          'url': l['url'] as String,
          'title': l['title'] as String?,
          'image': l['image'] as String?,
          'describe': l['describe'] as String?,
          'inflow_type': l['inflow_type'] as String?,
          'created_at': l['created_at'] as String,
          'updated_at': l['updated_at'] as String,
        });
      }

      // sqlite_sequence 보정 — 다음 insert의 auto-increment가 복구된 최댓값 뒤에서 시작하게
      await txn.rawUpdate(
        'UPDATE sqlite_sequence SET seq = '
        "(SELECT COALESCE(MAX(id), 0) FROM folder) WHERE name = 'folder'",
      );
      await txn.rawUpdate(
        'UPDATE sqlite_sequence SET seq = '
        "(SELECT COALESCE(MAX(id), 0) FROM link) WHERE name = 'link'",
      );
    });
    Log.i('restoreFromRemote ok: ${remoteFolders.length} folders, ${remoteLinks.length} links');
  }

  // ── 자동 머지 ──────────────────────────────────────────────────────────

  /// 로컬 + 원격을 머지한 결과로 양쪽을 교체.
  /// - 순수 계산 (computeMerge)
  /// - 로컬 SQLite 트랜잭션으로 원자적 교체
  /// - 원격은 backupToRemote() 재사용 (best-effort, 실패 시 dirty=true)
  /// 반환: 성공 시 MergeResult, 실패 시 null.
  Future<MergeResult?> mergeWithRemote() async {
    if (_isMerging) return null;
    final userId = _requireUserId();
    if (userId == null) return null;

    _isMerging = true;
    try {
      // 1) 양쪽 스냅샷 로드 + 2) 순수 계산 + 3) 로컬 트랜잭션은 한 묶음.
      // 여기서 실패하면 머지 전체 실패로 간주 — 예외 전파.
      final localFolders = await _folderRepo.getAllFolders();
      final localLinks = await _linkRepo.getAllLinks();
      final remoteFolders = await _client
          .from('folders')
          .select()
          .match({'user_id': userId});
      final remoteLinks =
          await _client.from('links').select().match({'user_id': userId});

      final result = computeMerge(
        localFolders: localFolders,
        localLinks: localLinks,
        remoteFolders: List<Map<String, dynamic>>.from(remoteFolders),
        remoteLinks: List<Map<String, dynamic>>.from(remoteLinks),
        mergeAt: DateTime.now().toUtc(),
      );

      await _applyMergeToLocal(result);

      // 4) 원격 full replace는 best-effort. 실패해도 로컬은 이미 머지 상태.
      //    backupToRemote가 내부에서 dirty=true 유지 → 다음 포그라운드 복귀 시 보정.
      try {
        final remoteOk = await backupToRemote();
        if (!remoteOk) {
          Log.e('mergeWithRemote: remote replace failed, dirty=true 유지');
        }
      } catch (e) {
        Log.e('mergeWithRemote: remote replace threw: $e');
      }

      Log.i('mergeWithRemote ok: ${result.stats}');

      // 5) 후처리: 외부에 저장된 id 참조 정리
      try {
        await const RecentFoldersRepository().clear();
      } catch (e) {
        Log.e('mergeWithRemote: recent clear failed: $e');
      }
      try {
        await ShareDataProvider.syncFoldersToShareDB();
      } catch (e) {
        Log.e('mergeWithRemote: share.db sync failed: $e');
      }

      return result;
    } finally {
      _isMerging = false;
    }
  }

  Future<void> _applyMergeToLocal(MergeResult result) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('link');
      await txn.delete('folder');

      // folders 먼저 (parent_id 없이)
      for (final f in result.folders) {
        final map = Map<String, dynamic>.from(f.toMap())..remove('parent_id');
        await txn.insert('folder', map);
      }

      // parent_id 2-pass update
      for (final f in result.folders) {
        if (f.parentId != null && f.id != null) {
          await txn.update(
            'folder',
            {'parent_id': f.parentId},
            where: 'id = ?',
            whereArgs: [f.id],
          );
        }
      }

      // links
      for (final l in result.links) {
        await txn.insert('link', l.toMap());
      }

      // sqlite_sequence 보정
      await txn.rawUpdate(
        'UPDATE sqlite_sequence SET seq = '
        "(SELECT COALESCE(MAX(id), 0) FROM folder) WHERE name = 'folder'",
      );
      await txn.rawUpdate(
        'UPDATE sqlite_sequence SET seq = '
        "(SELECT COALESCE(MAX(id), 0) FROM link) WHERE name = 'link'",
      );
    });
  }

  /// Pro → Free 전환 시 원격 전체 삭제.
  /// 실패해도 다음 백업이 full replace 라 자동 청소됨 (로그만 남김).
  Future<void> purgeRemote() async {
    final userId = _requireUserId();
    if (userId == null) return;
    try {
      await _client.from('links').delete().match({'user_id': userId});
      await _client.from('folders').delete().match({'user_id': userId});
      Log.i('purgeRemote ok');
    } catch (e) {
      Log.e('purgeRemote failed: $e');
    }
  }

  /// 테스트/디버깅용 — 백업 메타 초기화 (원격 데이터는 건드리지 않음).
  Future<void> clearLocalSyncMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastBackupAt);
    await prefs.remove(_kRemoteDirty);
    await prefs.remove(_kDirtySince);
  }
}
