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
}
