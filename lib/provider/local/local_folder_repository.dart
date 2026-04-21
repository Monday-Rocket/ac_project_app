import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
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

  /// 폴더 생성
  Future<int> createFolder(LocalFolder folder) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = folder.toMap()
      ..['created_at'] = now
      ..['updated_at'] = now;
    final id = await db.insert(_table, map);
    Log.i('Created folder: $id - ${folder.name}');
    return id;
  }

  /// 폴더 업데이트
  Future<int> updateFolder(LocalFolder folder) async {
    if (folder.id == null) {
      throw ArgumentError('Folder ID cannot be null for update');
    }
    final db = await _databaseHelper.database;
    final map = folder.toMap()..['updated_at'] = DateTime.now().toIso8601String();
    final count = await db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [folder.id],
    );
    Log.i('Updated folder: ${folder.id} - ${folder.name}');
    return count;
  }

  /// 폴더 삭제 (연결된 링크도 CASCADE로 삭제됨)
  Future<int> deleteFolder(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    Log.i('Deleted folder: $id');
    return count;
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
    final count = await db.update(
      _table,
      {
        'thumbnail': thumbnail,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
    Log.i('Updated folder thumbnail: $folderId');
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

  /// 폴더의 부모 변경. 순환 참조(자기 자신/후손으로 이동) 시 false 반환.
  Future<bool> moveFolder(int folderId, int? newParentId) async {
    if (newParentId != null) {
      if (folderId == newParentId) return false;
      final descendants = await getAllDescendants(folderId);
      if (descendants.any((f) => f.id == newParentId)) return false;
    }
    final db = await _databaseHelper.database;
    final count = await db.update(
      _table,
      {
        'parent_id': newParentId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
    Log.i('Moved folder: $folderId → parent=$newParentId');
    return count > 0;
  }
}
