import 'dart:async';
import 'dart:ui';

import 'package:ac_project_app/firebase_options.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/logger.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  await initSettings();
  // await initSqflite();
  runApp(const MyApp());
}

Future<void> initSqflite() async {
  final path = await ShareDataProvider.getShareDBUrl();

  Log.i('DB Path: $path');
  const folderDDL = '''
  create table folder( 
    seq integer primary key autoincrement, 
    name varchar(20) not null, 
    visible boolean not null default 1,
    imageLink varchar(2000) 
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
