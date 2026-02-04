import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/util/logger.dart';

class LocalLinkRepository {
  LocalLinkRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  static const String _table = 'link';

  /// 모든 링크 조회 (최신순)
  Future<List<LocalLink>> getAllLinks({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    var query = 'SELECT * FROM $_table ORDER BY created_at DESC';
    final args = <dynamic>[];

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
      if (offset != null) {
        query += ' OFFSET ?';
        args.add(offset);
      }
    }

    final result = await db.rawQuery(query, args);
    return result.map(LocalLink.fromMap).toList();
  }

  /// 폴더별 링크 조회
  Future<List<LocalLink>> getLinksByFolderId(
    int folderId, {
    int? limit,
    int? offset,
  }) async {
    final db = await _databaseHelper.database;
    var query = 'SELECT * FROM $_table WHERE folder_id = ? ORDER BY created_at DESC';
    final args = <dynamic>[folderId];

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
      if (offset != null) {
        query += ' OFFSET ?';
        args.add(offset);
      }
    }

    final result = await db.rawQuery(query, args);
    return result.map(LocalLink.fromMap).toList();
  }

  /// 링크 ID로 조회
  Future<LocalLink?> getLinkById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return LocalLink.fromMap(result.first);
  }

  /// 링크 생성
  Future<int> createLink(LocalLink link) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = link.toMap()
      ..['created_at'] = now
      ..['updated_at'] = now;
    final id = await db.insert(_table, map);
    Log.i('Created link: $id - ${link.url}');

    // 폴더 썸네일 업데이트 (첫 링크인 경우)
    await _updateFolderThumbnailIfNeeded(link.folderId, link.image);

    return id;
  }

  /// 링크 업데이트
  Future<int> updateLink(LocalLink link) async {
    if (link.id == null) {
      throw ArgumentError('Link ID cannot be null for update');
    }
    final db = await _databaseHelper.database;
    final map = link.toMap()..['updated_at'] = DateTime.now().toIso8601String();
    final count = await db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [link.id],
    );
    Log.i('Updated link: ${link.id}');
    return count;
  }

  /// 링크 삭제
  Future<int> deleteLink(int id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    Log.i('Deleted link: $id');
    return count;
  }

  /// 링크 폴더 이동
  Future<int> moveLink(int linkId, int newFolderId) async {
    final db = await _databaseHelper.database;
    final count = await db.update(
      _table,
      {
        'folder_id': newFolderId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [linkId],
    );
    Log.i('Moved link $linkId to folder $newFolderId');
    return count;
  }

  /// 여러 링크 폴더 이동
  Future<int> moveLinks(List<int> linkIds, int newFolderId) async {
    if (linkIds.isEmpty) return 0;

    final db = await _databaseHelper.database;
    final placeholders = List.filled(linkIds.length, '?').join(', ');
    final count = await db.rawUpdate(
      'UPDATE $_table SET folder_id = ?, updated_at = ? WHERE id IN ($placeholders)',
      [newFolderId, DateTime.now().toIso8601String(), ...linkIds],
    );
    Log.i('Moved ${linkIds.length} links to folder $newFolderId');
    return count;
  }

  /// 링크 검색 (제목, URL, 설명)
  Future<List<LocalLink>> searchLinks(String query, {int? limit}) async {
    final db = await _databaseHelper.database;
    var sql = '''
      SELECT * FROM $_table
      WHERE title LIKE ? OR url LIKE ? OR describe LIKE ?
      ORDER BY created_at DESC
    ''';
    final args = <dynamic>['%$query%', '%$query%', '%$query%'];

    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    final result = await db.rawQuery(sql, args);
    return result.map(LocalLink.fromMap).toList();
  }

  /// 폴더별 링크 개수 조회
  Future<int> getLinkCountByFolderId(int folderId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE folder_id = ?',
      [folderId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// 전체 링크 개수 조회
  Future<int> getTotalLinkCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    return result.first['count'] as int? ?? 0;
  }

  /// URL 중복 체크
  Future<bool> isUrlExists(String url) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE url = ?',
      [url],
    );
    return (result.first['count'] as int? ?? 0) > 0;
  }

  /// URL로 링크 조회
  Future<LocalLink?> getLinkByUrl(String url) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      _table,
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return LocalLink.fromMap(result.first);
  }

  /// 폴더 썸네일 업데이트 (필요한 경우)
  Future<void> _updateFolderThumbnailIfNeeded(int folderId, String? image) async {
    if (image == null) return;

    final db = await _databaseHelper.database;
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
      Log.i('Updated folder $folderId thumbnail');
    }
  }
}
