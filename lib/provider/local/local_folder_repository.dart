import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/folder_exceptions.dart';
import 'package:ac_project_app/provider/sync/pro_remote_hooks.dart';
import 'package:ac_project_app/util/logger.dart';

class LocalFolderRepository {
  LocalFolderRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  static const String _table = 'folder';

  /// 모든 폴더 조회 (링크 개수 포함)
  Future<List<LocalFolder>> getAllFolders() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      GROUP BY f.id
      ORDER BY f.is_classified ASC, f.created_at DESC
    ''');
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 분류된 폴더만 조회 (미분류 제외)
  Future<List<LocalFolder>> getClassifiedFolders() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      WHERE f.is_classified = 1
      GROUP BY f.id
      ORDER BY f.created_at DESC
    ''');
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 미분류 폴더 조회
  Future<LocalFolder?> getUnclassifiedFolder() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      WHERE f.is_classified = 0
      GROUP BY f.id
      LIMIT 1
    ''');
    if (result.isEmpty) return null;
    return LocalFolder.fromMap(result.first);
  }

  /// 폴더 ID로 조회
  Future<LocalFolder?> getFolderById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      WHERE f.id = ?
      GROUP BY f.id
    ''', [id]);
    if (result.isEmpty) return null;
    return LocalFolder.fromMap(result.first);
  }

  /// 폴더 생성.
  /// 미분류 폴더는 시스템이 관리하므로 is_classified=false 생성은 금지.
  /// 미분류 폴더를 부모로 지정하는 것도 금지.
  /// 형제 범위에서 동명 폴더가 있어도 거부.
  Future<int> createFolder(LocalFolder folder) async {
    if (!folder.isClassified) {
      throw const UnclassifiedCreationException(
        '미분류 폴더는 시스템이 관리합니다. 수동 생성 불가.',
      );
    }
    if (folder.parentId != null) {
      final parent = await getFolderById(folder.parentId!);
      if (parent == null) {
        throw const ParentNotFoundException('부모 폴더가 존재하지 않습니다.');
      }
      if (!parent.isClassified) {
        throw const ParentNotClassifiedException(
          '미분류 폴더 아래에는 하위 폴더를 만들 수 없습니다.',
        );
      }
    }
    if (await isSiblingNameTaken(folder.parentId, folder.name)) {
      throw const SiblingNameTakenException(
        '같은 위치에 이미 같은 이름의 폴더가 있습니다.',
      );
    }
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = folder.toMap()
      ..['created_at'] = now
      ..['updated_at'] = now;
    final id = await db.insert(_table, map);
    Log.i('Created folder: $id - ${folder.name}');
    await ProRemoteHooks.onFolderUpserted(folder.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  /// 같은 부모 아래에 동일한 이름의 **분류된** 폴더가 이미 있는지.
  /// parentId=null은 루트 범위. 시스템 관리 폴더(미분류)는 비교 대상에서 제외.
  /// 비교는 바이트-equal (대소문자 구분, 유니코드 정규화 없음).
  /// 호출부가 필요 시 이름을 trim한 뒤 전달해야 한다.
  Future<bool> isSiblingNameTaken(int? parentId, String name) async {
    final db = await _databaseHelper.database;
    final rows = parentId == null
        ? await db.query(
            _table,
            where: 'parent_id IS NULL AND name = ? AND is_classified = 1',
            whereArgs: [name],
            limit: 1,
          )
        : await db.query(
            _table,
            where: 'parent_id = ? AND name = ? AND is_classified = 1',
            whereArgs: [parentId, name],
            limit: 1,
          );
    return rows.isNotEmpty;
  }

  /// 폴더 업데이트. 미분류 폴더는 이름/부모 변경 모두 금지.
  Future<int> updateFolder(LocalFolder folder) async {
    if (folder.id == null) {
      throw ArgumentError('Folder ID cannot be null for update');
    }
    await _assertNotUnclassified(
      folder.id!,
      '미분류 폴더는 수정할 수 없습니다.',
    );
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = folder.toMap()..['updated_at'] = now;
    final count = await db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [folder.id],
    );
    Log.i('Updated folder: ${folder.id} - ${folder.name}');
    await ProRemoteHooks.onFolderUpserted(folder.copyWith(updatedAt: now));
    return count;
  }

  /// 폴더 삭제. 미분류 폴더는 삭제 불가.
  Future<int> deleteFolder(int id) async {
    await _assertNotUnclassified(id, '미분류 폴더는 삭제할 수 없습니다.');
    // CASCADE로 삭제될 후손 폴더 ID 미리 확보 (원격 정리용)
    final descendants = await getAllDescendants(id);
    final db = await _databaseHelper.database;
    final count = await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    Log.i('Deleted folder: $id');
    for (final f in descendants) {
      if (f.id != null) await ProRemoteHooks.onFolderDeleted(f.id!);
    }
    return count;
  }

  Future<void> _assertNotUnclassified(int folderId, String message) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      _table,
      columns: ['is_classified'],
      where: 'id = ?',
      whereArgs: [folderId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final isClassified = (rows.first['is_classified'] as int?) == 1;
    if (!isClassified) {
      throw StateError(message);
    }
  }

  /// 폴더 이름으로 검색
  Future<List<LocalFolder>> searchFolders(String query) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      WHERE f.name LIKE ?
      GROUP BY f.id
      ORDER BY f.created_at DESC
    ''', ['%$query%']);
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 폴더 썸네일 업데이트
  Future<int> updateThumbnail(int folderId, String? thumbnail) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      _table,
      {
        'thumbnail': thumbnail,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
    Log.i('Updated folder thumbnail: $folderId');
    final refreshed = await getFolderById(folderId);
    if (refreshed != null) await ProRemoteHooks.onFolderUpserted(refreshed);
    return count;
  }

  /// 폴더 개수 조회
  Future<int> getFolderCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    return result.first['count'] as int? ?? 0;
  }

  /// 최상위 폴더 (parent_id IS NULL)
  Future<List<LocalFolder>> getRootFolders() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      WHERE f.parent_id IS NULL
      GROUP BY f.id
      ORDER BY f.is_classified ASC, f.created_at DESC
    ''');
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 특정 폴더의 직계 자식 폴더
  Future<List<LocalFolder>> getChildFolders(int parentId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      LEFT JOIN link l ON f.id = l.folder_id
      WHERE f.parent_id = ?
      GROUP BY f.id
      ORDER BY f.created_at DESC
    ''', [parentId]);
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 특정 폴더 자신 + 모든 후손 (재귀 CTE)
  Future<List<LocalFolder>> getAllDescendants(int folderId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      WITH RECURSIVE subtree(id) AS (
        SELECT id FROM $_table WHERE id = ?
        UNION ALL
        SELECT f.id FROM $_table f
        JOIN subtree s ON f.parent_id = s.id
      )
      SELECT f.*, COUNT(l.id) as links_count
      FROM $_table f
      JOIN subtree s ON f.id = s.id
      LEFT JOIN link l ON l.folder_id = f.id
      GROUP BY f.id
      ORDER BY f.created_at DESC
    ''', [folderId]);
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 루트부터 해당 폴더까지의 경로 (브레드크럼)
  Future<List<LocalFolder>> getBreadcrumb(int folderId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      WITH RECURSIVE path(id, parent_id, depth) AS (
        SELECT id, parent_id, 0 FROM $_table WHERE id = ?
        UNION ALL
        SELECT f.id, f.parent_id, p.depth + 1
        FROM $_table f
        JOIN path p ON f.id = p.parent_id
      )
      SELECT f.*, COUNT(l.id) as links_count, p.depth as _depth
      FROM path p
      JOIN $_table f ON f.id = p.id
      LEFT JOIN link l ON l.folder_id = f.id
      GROUP BY f.id, p.depth
      ORDER BY p.depth DESC
    ''', [folderId]);
    return result.map(LocalFolder.fromMap).toList();
  }

  /// 각 폴더의 "자기 + 모든 후손" 재귀 링크 카운트
  Future<Map<int, int>> getRecursiveLinkCounts() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      WITH RECURSIVE subtree(id, root) AS (
        SELECT id, id FROM $_table
        UNION ALL
        SELECT f.id, s.root FROM $_table f
        JOIN subtree s ON f.parent_id = s.id
      )
      SELECT s.root AS folder_id, COUNT(l.id) AS total
      FROM subtree s
      LEFT JOIN link l ON l.folder_id = s.id
      GROUP BY s.root
    ''');
    final counts = <int, int>{};
    for (final row in result) {
      final folderId = row['folder_id'] as int?;
      if (folderId == null) continue;
      counts[folderId] = (row['total'] as int?) ?? 0;
    }
    return counts;
  }

  /// 폴더의 부모 변경. 다음 경우 false 반환:
  /// - 자기 자신이나 자기 후손으로 이동 (순환 참조)
  /// - 미분류 폴더는 이동 불가 (항상 최상위 고정)
  /// - 미분류 폴더를 새 부모로 지정 (하위 폴더 금지)
  Future<bool> moveFolder(int folderId, int? newParentId) async {
    final target = await getFolderById(folderId);
    if (target == null || !target.isClassified) return false;
    if (newParentId != null) {
      if (folderId == newParentId) return false;
      final parent = await getFolderById(newParentId);
      if (parent == null || !parent.isClassified) return false;
      final descendants = await getAllDescendants(folderId);
      if (descendants.any((f) => f.id == newParentId)) return false;
    }
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      _table,
      {
        'parent_id': newParentId,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
    Log.i('Moved folder: $folderId → parent=$newParentId');
    if (count > 0) {
      final refreshed = await getFolderById(folderId);
      if (refreshed != null) await ProRemoteHooks.onFolderUpserted(refreshed);
    }
    return count > 0;
  }
}
