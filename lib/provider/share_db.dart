import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:sqflite/sqflite.dart';

class ShareDB {
  static Future<void> initSqflite() async {
    final path = await ShareDataProvider.getShareDBUrl();
    Log.i('path: $path');

    const folderDDL = '''
  create table if not exists folder( 
    seq integer primary key autoincrement, 
    name varchar(200) not null unique, 
    visible boolean not null default 1,
    imageLink varchar(2000),
    time timestamp default current_timestamp not null 
  );
  ''';

    final database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        Log.i('DB 생성됨');
        await db.execute(folderDDL);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          Log.i('DB upgraded: $newVersion');
          await db.execute('drop table folder;');
          await db.execute(folderDDL);
          await SharedPrefHelper.saveKeyValue('isFirst', true);
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

  static Future<void> changeName(Folder folder, String name) async {
    final db = await _getDB();

    final rows = await db.query(
      'folder',
      where: 'name = ?',
      whereArgs: [folder.name],
    );
    Log.i('rows: $rows');
    final seq = rows[0]['seq'];
    await db.update(
      'folder',
      {'name': name},
      where: 'seq = ?',
      whereArgs: [seq],
    );

    await db.close();
  }

  static Future<void> changeVisible(Folder folder) async {
    final db = await _getDB();
    await db.rawUpdate(
      'UPDATE folder set visible = ? where name = ?',
      [if (folder.visible!) 0 else 1, folder.name],
    );
    await db.close();
  }

  static Future<void> changeFolder(Folder folder) async {
    final db = await _getDB();
    await db.update(
      'folder',
      {
        'name': folder.name,
        'visible': folder.visible! ? 1 : 0,
      },
      where: 'name = ?',
      whereArgs: [folder.name],
    );
    await db.close();
  }

  static Future<void> deleteFolder(Folder folder) async {
    final db = await _getDB();
    await db.delete('folder', where: 'name = ?', whereArgs: [folder.name]);
    await db.close();
  }

  static Future<bool> insert(Folder folder) async {
    final db = await _getDB();
    final result = await db.rawInsert(
      'INSERT into folder(name, visible) values(?, ?)',
      [folder.name, if (folder.visible!) 1 else 0],
    );
    await db.close();
    return result != 0;
  }

  static Future<void> deleteAllFolder() async {
    final db = await _getDB();
    await db.execute('delete from folder');
    await db.close();
  }

  static Future<bool> loadData(List<Folder> folders) async {
    try {
      final db = await _getDB();
      for (final folder in folders) {
        await db.insert('folder', {
          'name': folder.name ?? '',
          'visible': folder.visible! ? 1 : 0,
          'imageLink': folder.thumbnail ?? '',
          'time': folder.time,
        });
      }
      return true;
    } catch (e) {
      Log.e(e.toString());
      return false;
    }
  }
}
