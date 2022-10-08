import 'dart:async';

import 'package:ac_project_app/firebase_options.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

Future<void> main() async {
  await initSettings();
  runApp(const MyApp());
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
    //if (Platform.isAndroid) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.login,
        onGenerateRoute: Pages.getPages,
        themeMode: ThemeMode.light,
      );
    // } else {
    //   return const CupertinoApp(
    //     debugShowCheckedModeBanner: false,
    //     initialRoute: Routes.login,
    //     onGenerateRoute: Pages.getPages,
    //   );
    // }
  }
}
