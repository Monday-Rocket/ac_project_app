import 'dart:async';

import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await initSettings();
  await initSqflite();
  unawaited(ShareDataProvider.getNewLinks());
  unawaited(ShareDataProvider.getNewFolders());
  runApp(const MyApp());
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
