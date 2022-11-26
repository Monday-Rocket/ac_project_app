import 'dart:async';

import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  await initSettings();
  await ShareDB.initSqflite();
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
  static Widget create() {
    return BlocProvider<GetProfileInfoCubit>(
      create: (_) => GetProfileInfoCubit(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.splash,
        onGenerateRoute: Pages.getPages,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          fontFamily: 'Pretendard',
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
