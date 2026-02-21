import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Native Share Panel에서 일괄 저장을 처리하는 Repository
class LocalBulkRepository {
  LocalBulkRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// Native Share Panel에서 전달받은 링크들을 일괄 저장
  /// 기존 loadServerData() 로직을 대체
  Future<BulkInsertResult> bulkInsertFromNative({
    required List<Map<String, dynamic>> links,
    required List<Map<String, dynamic>> folders,
  }) async {
    final db = await _databaseHelper.database;
    var insertedFolders = 0;
    var insertedLinks = 0;
    final folderIdMap = <String, int>{};

    await db.transaction((txn) async {
      // 1. 폴더 저장 (이름 기준 중복 체크)
      for (final folderData in folders) {
        final name = folderData['name'] as String? ?? '미분류';

        // 기존 폴더 확인
        final existing = await txn.query(
          'folder',
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );

        int folderId;
        if (existing.isNotEmpty) {
          folderId = existing.first['id'] as int;
        } else {
          final now = DateTime.now().toIso8601String();
          folderId = await txn.insert('folder', {
            'name': name,
            'thumbnail': folderData['thumbnail'] as String?,
            'is_classified': name == '미분류' ? 0 : 1,
            'created_at': now,
            'updated_at': now,
          });
          insertedFolders++;
        }

        // Native에서 넘어온 임시 ID와 실제 DB ID 매핑
        final nativeId = folderData['id']?.toString() ?? name;
        folderIdMap[nativeId] = folderId;
      }

      // 2. 미분류 폴더 ID 확보
      final unclassified = await txn.query(
        'folder',
        where: 'is_classified = 0',
        limit: 1,
      );
      final unclassifiedId = unclassified.isNotEmpty
          ? unclassified.first['id'] as int
          : 1; // 기본값

      // 3. 링크 저장 (URL 기준 중복 체크)
      for (final linkData in links) {
        final url = linkData['url'] as String;

        // URL 중복 체크
        final existingLink = await txn.query(
          'link',
          where: 'url = ?',
          whereArgs: [url],
          limit: 1,
        );

        if (existingLink.isEmpty) {
          // 폴더 ID 매핑 (Native에서 넘어온 folder_id 또는 이름으로 매핑)
          final nativeFolderId = linkData['folder_id']?.toString();
          final folderName = linkData['folder_name'] as String?;
          int folderId;

          if (nativeFolderId != null && folderIdMap.containsKey(nativeFolderId)) {
            folderId = folderIdMap[nativeFolderId]!;
          } else if (folderName != null && folderIdMap.containsKey(folderName)) {
            folderId = folderIdMap[folderName]!;
          } else if (folderName != null) {
            // 기존 폴더에서 이름으로 검색
            final existingFolder = await txn.query(
              'folder',
              where: 'name = ?',
              whereArgs: [folderName],
              limit: 1,
            );
            if (existingFolder.isNotEmpty) {
              folderId = existingFolder.first['id'] as int;
            } else {
              folderId = unclassifiedId;
            }
          } else {
            folderId = unclassifiedId;
          }

          final now = DateTime.now().toIso8601String();
          await txn.insert('link', {
            'folder_id': folderId,
            'url': url,
            'title': linkData['title'] as String?,
            'image': linkData['image'] as String?,
            'describe': linkData['describe'] as String?,
            'inflow_type': linkData['inflow_type'] as String? ?? 'share',
            'created_at': now,
            'updated_at': now,
          });
          insertedLinks++;

          // 폴더 썸네일 업데이트
          final image = linkData['image'] as String?;
          if (image != null) {
            await _updateFolderThumbnailIfNeeded(txn, folderId, image);
          }
        }
      }
    });

    Log.i('Bulk insert completed: $insertedFolders folders, $insertedLinks links');
    return BulkInsertResult(
      insertedFolders: insertedFolders,
      insertedLinks: insertedLinks,
    );
  }

  /// 서버 데이터 마이그레이션 (Save Offline 과정에서 사용)
  Future<BulkInsertResult> migrateFromServer({
    required List<Map<String, dynamic>> serverFolders,
    required List<Map<String, dynamic>> serverLinks,
  }) async {
    final db = await _databaseHelper.database;
    var insertedFolders = 0;
    var insertedLinks = 0;
    final serverToLocalFolderIdMap = <int, int>{};

    await db.transaction((txn) async {
      // 1. 서버 폴더 마이그레이션
      for (final serverFolder in serverFolders) {
        final serverId = serverFolder['id'] as int?;
        final name = serverFolder['name'] as String? ?? '미분류';
        final _ = serverFolder['visible'] as bool? ?? true;

        // 미분류 폴더는 기존 것 사용 (serverId가 null이거나 이름이 '미분류'인 경우)
        if (serverId == null || name == '미분류') {
          final existing = await txn.query(
            'folder',
            where: 'is_classified = 0',
            limit: 1,
          );
          if (existing.isNotEmpty) {
            if (serverId != null) {
              serverToLocalFolderIdMap[serverId] = existing.first['id'] as int;
            }
            continue;
          }
        }

        // 이름 기준 중복 체크
        final existingByName = await txn.query(
          'folder',
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );

        int localId;
        if (existingByName.isNotEmpty) {
          // 기존 폴더 사용
          localId = existingByName.first['id'] as int;
        } else {
          // 새 폴더 생성 (미분류가 아닌 모든 폴더는 is_classified = 1)
          final now = DateTime.now().toIso8601String();
          localId = await txn.insert('folder', {
            'name': name,
            'thumbnail': serverFolder['thumbnail'] as String?,
            'is_classified': 1, // visible은 공개/비공개 설정이므로 is_classified와 무관
            'created_at': serverFolder['created_at'] as String? ?? now,
            'updated_at': now,
          });
          insertedFolders++;
        }

        if (serverId != null) {
          serverToLocalFolderIdMap[serverId] = localId;
        }
      }

      // 2. 미분류 폴더 ID 확보
      final unclassified = await txn.query(
        'folder',
        where: 'is_classified = 0',
        limit: 1,
      );
      final unclassifiedId = unclassified.isNotEmpty
          ? unclassified.first['id'] as int
          : 1;

      // 3. 서버 링크 마이그레이션
      for (final serverLink in serverLinks) {
        final url = serverLink['url'] as String? ?? '';
        if (url.isEmpty) continue;

        // Link.toJson()은 'folderId' (camelCase)로 저장
        final serverFolderId = (serverLink['folderId'] ?? serverLink['folder_id']) as int?;
        final mappedFolderId = serverFolderId != null
            ? serverToLocalFolderIdMap[serverFolderId]
            : null;
        final folderId = mappedFolderId ?? unclassifiedId;
        Log.i('[Migration] 링크 저장: serverFolderId=$serverFolderId, mappedFolderId=$mappedFolderId, folderId=$folderId, url=$url');
        Log.i('[Migration] serverToLocalFolderIdMap: $serverToLocalFolderIdMap');

        final now = DateTime.now().toIso8601String();
        await txn.insert('link', {
          'folder_id': folderId,
          'url': url,
          'title': serverLink['title'] as String?,
          'image': serverLink['image'] as String?,
          'describe': serverLink['describe'] as String?,
          'inflow_type': serverLink['inflow_type'] as String?,
          // Link.toJson()은 'created_date_time'으로 저장
          'created_at': (serverLink['created_date_time'] ?? serverLink['created_at']) as String? ?? now,
          'updated_at': now,
        });
        insertedLinks++;

        // 폴더 썸네일 업데이트
        final image = serverLink['image'] as String?;
        if (image != null) {
          await _updateFolderThumbnailIfNeeded(txn, folderId, image);
        }
      }
    });

    Log.i('Server migration completed: $insertedFolders folders, $insertedLinks links');
    return BulkInsertResult(
      insertedFolders: insertedFolders,
      insertedLinks: insertedLinks,
    );
  }

  /// 단일 링크 빠른 저장 (Share Extension에서 사용)
  Future<int> quickSaveLink({
    required String url,
    String? title,
    String? image,
    String? describe,
    int? folderId,
  }) async {
    final db = await _databaseHelper.database;

    // URL 중복 체크
    final existingLink = await db.query(
      'link',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );

    if (existingLink.isNotEmpty) {
      Log.i('Link already exists: $url');
      return existingLink.first['id'] as int;
    }

    // 폴더 ID가 없으면 미분류 폴더 사용
    int targetFolderId;
    if (folderId != null) {
      targetFolderId = folderId;
    } else {
      final unclassified = await db.query(
        'folder',
        where: 'is_classified = 0',
        limit: 1,
      );
      targetFolderId = unclassified.isNotEmpty
          ? unclassified.first['id'] as int
          : 1;
    }

    final now = DateTime.now().toIso8601String();
    final linkId = await db.insert('link', {
      'folder_id': targetFolderId,
      'url': url,
      'title': title,
      'image': image,
      'describe': describe,
      'inflow_type': 'share',
      'created_at': now,
      'updated_at': now,
    });

    // 폴더 썸네일 업데이트
    if (image != null) {
      await _updateFolderThumbnailIfNeeded(db, targetFolderId, image);
    }

    Log.i('Quick saved link: $linkId - $url');
    return linkId;
  }

  Future<void> _updateFolderThumbnailIfNeeded(
    DatabaseExecutor db,
    int folderId,
    String image,
  ) async {
    final folder = await db.query(
      'folder',
      columns: ['thumbnail'],
      where: 'id = ?',
      whereArgs: [folderId],
      limit: 1,
    );

    if (folder.isNotEmpty && folder.first['thumbnail'] == null) {
      await db.update(
        'folder',
        {
          'thumbnail': image,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [folderId],
      );
    }
  }
}

/// 일괄 삽입 결과
class BulkInsertResult {
  const BulkInsertResult({
    required this.insertedFolders,
    required this.insertedLinks,
  });

  final int insertedFolders;
  final int insertedLinks;

  int get totalInserted => insertedFolders + insertedLinks;
}
