import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:sqflite/sqflite.dart';

class ShareDB {
  static Future<void> initSqflite() async {
    final path = await ShareDataProvider.getShareDBUrl();
    Log.i('path: $path');

    const folderDDL = '''
  create table if not exists folder( 
    seq integer primary key autoincrement, 
    name varchar(200) not null, 
    visible boolean not null default 1,
    imageLink varchar(2000),
    time timestamp default current_timestamp not null 
  );
  ''';

    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        Log.i('DB 생성됨');
        await db.execute(folderDDL);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          Log.i('DB upgraded: $newVersion');
          await db.execute('drop table folder;');
          await db.execute(folderDDL);
        }
      },
    );
    await database.close();
  }

  static Future<Database> _getDB() async {
    final path = await ShareDataProvider.getShareDBUrl();
    Log.i(path);
    return openDatabase(path);
  }

  static Future<void> changeVisible(Folder folder) async {
    final db = await _getDB();
    await db.rawUpdate(
      'UPDATE folder set visible = ? where name = ?',
      [if (folder.visible!) 0 else 1, folder.name],
    );
    await db.close();
  }

  static Future<void> deleteFolder(Folder folder) async {
    final db = await _getDB();
    await db.delete('folder', where: 'name = ?', whereArgs: [folder.name]);
    await db.close();
  }

  static Future<void> insert(Folder folder) async {
    final db = await _getDB();
    await db.rawInsert(
      'INSERT into folder(name, visible) values(?, ?)',
      [folder.name, if (folder.visible!) 1 else 0],
    );
    await db.close();
  }
}
