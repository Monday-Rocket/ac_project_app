import 'dart:async';

import 'package:ac_project_app/firebase_options.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  await initSettings();
  await initSqflite();
  runApp(const MyApp());
}

Future<void> initSqflite() async {
  final path = '${await getDatabasesPath()}/share.db';
  Log.i('DB Path: $path');
  const folderSql = 'create table folder( '
      'seq integer primary key autoincrement, '
      'name varchar(20) not null, '
      'visible boolean not null default 1 '
      ');';

  const linkSql = 'create table link( '
      'seq integer primary key autoincrement, '
      'link varchar(2000) not null, '
      'comment varchar(300), '
      'folder_seq int(11), '
      'image_link varchar(2000) '
      ');';
  const folderTempSql = 'create table folder_temp( '
      'seq integer primary key autoincrement, '
      'name varchar(20) not null, '
      'visible boolean not null default 1 '
      ');';

  const linkTempSql = 'create table link_temp( '
      'seq integer primary key autoincrement, '
      'link varchar(2000) not null, '
      'comment varchar(300), '
      'folder_seq int(11), '
      'image_link varchar(2000) '
      ');';
  final database = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      Log.i('DB 생성됨');
      await db.execute(folderTempSql);
      await db.execute(linkTempSql);
      await db.execute(folderSql);
      await db.execute(linkSql);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < newVersion) {
        Log.i('DB upgraded: $newVersion');
        await db.execute('drop table link;');
        await db.execute('drop table folder;');
        await db.execute('drop table link_temp;');
        await db.execute('drop table folder_temp;');
        await db.execute(folderTempSql);
        await db.execute(linkTempSql);
        await db.execute(folderSql);
        await db.execute(linkSql);
      }
    },
  );
  final version = await database.getVersion();
  await database.close();
}

Future<void> initSettings() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  );
  KakaoSdk.init(nativeAppKey: dotenv.env['kakao.api.key']);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'ac_project',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app();
  }
  WidgetsFlutterBinding.ensureInitialized();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiPlatformApp.create();
  }
}

class MultiPlatformApp {
  static StatefulWidget create() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      onGenerateRoute: Pages.getPages,
      themeMode: ThemeMode.light,
      theme: ThemeData(fontFamily: 'Pretendard'),
    );
  }
}
