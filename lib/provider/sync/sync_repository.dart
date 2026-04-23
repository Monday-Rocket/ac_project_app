import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/sync/pro_mutate.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [SyncRepository.backupToRemote] 진행 단계. UI 로딩 표시용.
enum BackupPhase {
  preparing,
  uploadingFolders,
  uploadingLinks,
}

/// Pro 백업/복구 + 원격 CRUD 쓰기 전담 Repository.
///
/// 정책 요약 (SYNC_MODEL_V2):
/// - Free: 로컬 SQLite 가 진실. 원격 미사용.
/// - Pro: 서버가 진실. 로컬은 서버의 읽기 캐시 + 미러.
/// - 전환점(Free↔Pro)에서만 full replace 가 발생.
/// - CRUD 원격 쓰기는 [proMutate] 로 감싸 오프라인/서버 오류를 호출부로 상향. dirty flag 폐기.
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
  static const _kLastPullAt = 'lp_last_pull_at';

  /// Pull 연속 호출 방지 debounce. lifecycle/화면 진입 다중 트리거 대비.
  static const Duration _pullDebounce = Duration(seconds: 5);

  bool _isBackingUp = false;
  bool _isPulling = false;

  /// Pro 상태에서 원격 호출이 오프라인 예외로 실패하면 true 로 전환.
  /// 성공 pull 로 다시 false 로 복귀. UI 는 이 값을 구독해 팝업을 노출한다.
  final ValueNotifier<bool> offlineNotifier = ValueNotifier(false);

  void markOffline() {
    if (!offlineNotifier.value) offlineNotifier.value = true;
  }

  void clearOffline() {
    if (offlineNotifier.value) offlineNotifier.value = false;
  }

  /// Supabase 호출 모킹이 어려워 parent 해결 경로만 테스트에서 오버라이드할 수 있게 한다.
  @visibleForTesting
  Future<String?> Function(String userId, int localFolderId)?
      resolveRemoteFolderIdForTest;

  String? _requireUserId() => _client.auth.currentUser?.id;

  Future<String?> _resolveFolderOrTestHook(String userId, int localId) {
    final hook = resolveRemoteFolderIdForTest;
    if (hook != null) return hook(userId, localId);
    return _resolveRemoteFolderId(userId, localId);
  }

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

  /// 마지막 원격 pull 완료 시각. UI 오프라인 캡션("최근 동기화 MM/DD HH:mm") 용.
  Future<DateTime?> getLastPullAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastPullAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _setLastPullAtNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastPullAt, DateTime.now().toIso8601String());
  }

  // ── 개별 upsert/delete (Pro CRUD 원격 전파) ─────────────────────────

  Future<void> upsertFolderRemote(LocalFolder folder) async {
    final userId = _requireUserId();
    if (userId == null || folder.id == null) return;

    String? parentServerId;
    if (folder.parentId != null) {
      parentServerId =
          await _resolveFolderOrTestHook(userId, folder.parentId!);
      if (parentServerId == null) {
        // 부모 원격 매핑이 없으면 원격 쓰기를 건너뛴다. 다음 lifecycle 의
        // full-pull 에서 서버 상태가 진실로 취급되므로 자연 정정된다.
        Log.e('upsertFolderRemote: parent not found in remote, skipping');
        return;
      }
    }

    await proMutate<void>(
      remote: () => _client.from('folders').upsert({
        'user_id': userId,
        'client_id': folder.id,
        'parent_id': parentServerId,
        'name': folder.name,
        'thumbnail': folder.thumbnail,
        'is_classified': folder.isClassified,
        'created_at': folder.createdAt,
        'updated_at': folder.updatedAt,
      }, onConflict: 'user_id,client_id'),
    );
  }

  Future<void> upsertLinkRemote(LocalLink link) async {
    final userId = _requireUserId();
    if (userId == null || link.id == null) return;

    final folderServerId =
        await _resolveFolderOrTestHook(userId, link.folderId);
    if (folderServerId == null) {
      Log.e('upsertLinkRemote: folder not found in remote, skipping');
      return;
    }

    await proMutate<void>(
      remote: () => _client.from('links').upsert({
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
      }, onConflict: 'user_id,client_id'),
    );
  }

  Future<void> deleteFolderRemote(int localFolderId) async {
    final userId = _requireUserId();
    if (userId == null) return;
    await proMutate<void>(
      remote: () => _client
          .from('folders')
          .delete()
          .match({'user_id': userId, 'client_id': localFolderId}),
    );
  }

  Future<void> deleteLinkRemote(int localLinkId) async {
    final userId = _requireUserId();
    if (userId == null) return;
    await proMutate<void>(
      remote: () => _client
          .from('links')
          .delete()
          .match({'user_id': userId, 'client_id': localLinkId}),
    );
  }

  Future<String?> _resolveRemoteFolderId(
      String userId, int localFolderId) async {
    final rows = await _client
        .from('folders')
        .select('id')
        .match({'user_id': userId, 'client_id': localFolderId}).limit(1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  // ── 백업 (full replace) — Free → Pro 전환 전용 ───────────────────────

  /// 로컬 스냅샷으로 원격을 full replace.
  /// SYNC_MODEL_V2 §2.1: Free → Pro 전환 시에만 호출. Pro 활성 기간의 동기화에는 쓰지 않는다.
  ///
  /// [onPhase] — 단계 진행 통지 콜백. 로딩 UI 가 업로드 중임을 표현하기 위해 사용.
  /// 순서: preparing → uploadingFolders → uploadingLinks.
  Future<bool> backupToRemote({
    void Function(BackupPhase phase, {int? current, int? total})? onPhase,
  }) async {
    if (_isBackingUp) return false;
    final userId = _requireUserId();
    if (userId == null) return false;

    _isBackingUp = true;
    try {
      onPhase?.call(BackupPhase.preparing);
      final folders = await _folderRepo.getAllFolders();
      final links = await _linkRepo.getAllLinks();

      // 1) 원격 초기화
      await _client.from('links').delete().match({'user_id': userId});
      await _client.from('folders').delete().match({'user_id': userId});

      // 2) 폴더 INSERT (parent_id 없이)
      onPhase?.call(BackupPhase.uploadingFolders, total: folders.length);
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
        await _client.from('folders').update({'parent_id': parentRemote}).match(
            {'user_id': userId, 'client_id': f.id!});
      }

      // 5) 링크 INSERT (folder_id 매핑)
      onPhase?.call(BackupPhase.uploadingLinks, total: links.length);
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
      Log.i(
          'backupToRemote ok: ${folders.length} folders, ${links.length} links');
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
        .match({'user_id': userId}).limit(1);
    return rows.isNotEmpty;
  }

  // ── 복구 / 주기 pull ─────────────────────────────────────────────────

  /// 원격 → 로컬 full replace.
  /// SYNC_MODEL_V2 §2.2/2.3: Pro 활성 기간의 주기 pull, Pro→Free 전환 시 모두 동일.
  Future<void> restoreFromRemote() async {
    final userId = _requireUserId();
    if (userId == null) return;

    // 1) 원격 다운로드
    final remoteFolders =
        await _client.from('folders').select().match({'user_id': userId});
    final remoteLinks =
        await _client.from('links').select().match({'user_id': userId});

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
    Log.i(
        'restoreFromRemote ok: ${remoteFolders.length} folders, ${remoteLinks.length} links');
  }

  /// Pro 활성 기간의 주기 pull 엔트리.
  /// SYNC_MODEL_V2 §2.2: lifecycle resumed / 화면 진입 / 로그인 성공 시 호출.
  ///
  /// - [force] 가 false(기본)면 마지막 pull 로부터 [_pullDebounce] 미만일 때 skip.
  /// - 중복 호출 방지: 이미 pulling 중이면 skip.
  /// - 오프라인/네트워크 예외는 로그만 남기고 삼킨다 (다음 트리거에 재시도).
  /// - 서버 진실을 기준으로 로컬이 full replace 되므로 호출부는 이후 UI 갱신만 하면 된다.
  ///
  /// 반환: 실제 pull 이 수행돼 로컬이 변경됐으면 true, skip 됐으면 false.
  Future<bool> pullFromRemote({bool force = false}) async {
    if (_isPulling) return false;
    final userId = _requireUserId();
    if (userId == null) return false;

    if (!force) {
      final last = await getLastPullAt();
      if (last != null &&
          DateTime.now().difference(last) < _pullDebounce) {
        return false;
      }
    }

    _isPulling = true;
    try {
      await restoreFromRemote();
      await _setLastPullAtNow();
      clearOffline();
      return true;
    } on ProMutateOfflineException catch (e) {
      Log.e('pullFromRemote offline: $e');
      markOffline();
      return false;
    } catch (e) {
      // 네트워크 계열 예외 식별: SocketException / TimeoutException / HttpException / ClientException.
      if (isOfflineException(e)) {
        Log.e('pullFromRemote offline (raw): $e');
        markOffline();
      } else {
        Log.e('pullFromRemote failed: $e');
      }
      return false;
    } finally {
      _isPulling = false;
    }
  }

  /// Pro → Free 전환 시 원격 전체 삭제 (즉시 purge 옵션, 미사용).
  /// v2 에서는 Grace period 후 서버 cron 이 정리하므로 클라이언트 호출은 기본적으로 불필요.
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

  /// 테스트/디버깅용 — 백업/pull 메타 초기화 (원격 데이터는 건드리지 않음).
  Future<void> clearLocalSyncMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastBackupAt);
    await prefs.remove(_kLastPullAt);
  }
}
