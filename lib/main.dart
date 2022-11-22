import 'dart:async';

import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await initSettings();
  await initSqflite();
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
      initialRoute: Routes.profile,
      onGenerateRoute: Pages.getPages,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        brightness: Brightness.light,
      ),
    );
  }
}
