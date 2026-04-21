import 'package:ac_project_app/util/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._({String? dbName}) : _dbName = dbName ?? _defaultDbName;

  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _database;

  static const String _defaultDbName = 'linkpool_local.db';
  static const int _dbVersion = 2;

  final String _dbName;

  /// 테스트용 인스턴스 생성 (고유한 DB 이름 사용)
  static DatabaseHelper createForTest({String? dbName}) {
    return DatabaseHelper._(dbName: dbName ?? 'test_${DateTime.now().microsecondsSinceEpoch}.db');
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    Log.i('Database path: $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    Log.i('Creating database tables...');

    // folder 테이블 (v2 스키마: parent_id 포함)
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

    // link 테이블
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

    // 인덱스
    await db.execute('CREATE INDEX idx_folder_parent_id ON folder(parent_id)');
    await db.execute('CREATE INDEX idx_link_folder_id ON link(folder_id)');
    await db.execute('CREATE INDEX idx_link_created_at ON link(created_at DESC)');
    await db.execute('CREATE INDEX idx_link_title ON link(title)');

    // 미분류 폴더 기본 생성
    await db.insert('folder', {
      'name': '미분류',
      'is_classified': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    Log.i('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Log.i('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // v2: 중첩 폴더 지원. folder 테이블에 parent_id 컬럼 추가.
      // 기존 폴더는 모두 parent_id = NULL(최상위)로 유지됨.
      await db.execute(
        'ALTER TABLE folder ADD COLUMN parent_id INTEGER '
        'REFERENCES folder(id) ON DELETE CASCADE',
      );
      await db.execute('CREATE INDEX idx_folder_parent_id ON folder(parent_id)');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    Log.i('Database deleted');
  }
}
