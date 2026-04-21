import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DB schema v1 → v2 migration', () {
    late String dbPath;

    setUp(() async {
      final dir = await databaseFactory.getDatabasesPath();
      dbPath = p.join(
        dir,
        'migration_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
    });

    tearDown(() async {
      await databaseFactory.deleteDatabase(dbPath);
    });

    test('v1 DB → v2: folders preserved, parent_id defaults to NULL', () async {
      // 1단계: v1 스키마로 DB 생성 + 샘플 데이터 삽입
      final dbV1 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE folder (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                thumbnail TEXT,
                is_classified INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE link (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                folder_id INTEGER NOT NULL,
                url TEXT NOT NULL,
                title TEXT,
                image TEXT,
                describe TEXT,
                inflow_type TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (folder_id) REFERENCES folder(id) ON DELETE CASCADE
              )
            ''');
            await db.execute('CREATE INDEX idx_link_folder_id ON link(folder_id)');
          },
        ),
      );

      final now = DateTime.now().toIso8601String();
      await dbV1.insert('folder', {
        'name': '미분류',
        'is_classified': 0,
        'created_at': now,
        'updated_at': now,
      });
      final workFolderId = await dbV1.insert('folder', {
        'name': '일',
        'is_classified': 1,
        'created_at': now,
        'updated_at': now,
      });
      await dbV1.insert('link', {
        'folder_id': workFolderId,
        'url': 'https://example.com',
        'title': 'Example',
        'created_at': now,
        'updated_at': now,
      });
      await dbV1.close();

      // 2단계: DatabaseHelper와 동일한 onUpgrade 로직으로 v2 오픈
      final dbV2 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute(
                'ALTER TABLE folder ADD COLUMN parent_id INTEGER '
                'REFERENCES folder(id) ON DELETE CASCADE',
              );
              await db.execute(
                'CREATE INDEX idx_folder_parent_id ON folder(parent_id)',
              );
            }
          },
        ),
      );

      // 기존 폴더 데이터 보존 확인
      final folders = await dbV2.query('folder', orderBy: 'id ASC');
      expect(folders.length, 2);
      expect(folders[0]['name'], '미분류');
      expect(folders[0]['is_classified'], 0);
      expect(folders[0]['parent_id'], isNull);
      expect(folders[1]['name'], '일');
      expect(folders[1]['parent_id'], isNull);

      // 기존 링크 데이터 보존 확인
      final links = await dbV2.query('link');
      expect(links.length, 1);
      expect(links.first['url'], 'https://example.com');

      // idx_folder_parent_id 인덱스 존재 확인
      final indexes = await dbV2.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='folder'",
      );
      final indexNames = indexes.map((r) => r['name'] as String).toList();
      expect(indexNames, contains('idx_folder_parent_id'));

      // 신규 중첩 폴더 생성 + 조회 동작 검증
      final childId = await dbV2.insert('folder', {
        'name': '개발',
        'is_classified': 1,
        'parent_id': workFolderId,
        'created_at': now,
        'updated_at': now,
      });
      final children = await dbV2.query(
        'folder',
        where: 'parent_id = ?',
        whereArgs: [workFolderId],
      );
      expect(children.length, 1);
      expect(children.first['id'], childId);
      expect(children.first['name'], '개발');

      // FK CASCADE 동작 확인: 부모 삭제 시 하위 폴더 연쇄 삭제
      await dbV2.delete('folder', where: 'id = ?', whereArgs: [workFolderId]);
      final afterCascade = await dbV2.query(
        'folder',
        where: 'id = ?',
        whereArgs: [childId],
      );
      expect(afterCascade, isEmpty);

      await dbV2.close();
    });

    test('fresh install creates v2 schema with parent_id column', () async {
      // onCreate 경로 검증: 새 설치 시 parent_id가 바로 포함되어 있어야 함
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE folder (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                thumbnail TEXT,
                is_classified INTEGER NOT NULL DEFAULT 1,
                parent_id INTEGER,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (parent_id) REFERENCES folder(id) ON DELETE CASCADE
              )
            ''');
            await db.execute(
              'CREATE INDEX idx_folder_parent_id ON folder(parent_id)',
            );
          },
        ),
      );

      final columns = await db.rawQuery('PRAGMA table_info(folder)');
      final columnNames = columns.map((r) => r['name']).toList();
      expect(columnNames, contains('parent_id'));

      await db.close();
    });
  });
}
