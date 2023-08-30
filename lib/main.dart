import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/provider/global_providers.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';

Future<void> main() async {
  await initSettings();
  await ShareDB.initSqflite();
  locator();

  final gsReference =
  FirebaseStorage.instance.refFromURL('gs://ac-project-d04ee.appspot.com/img_01_on.png');

  print(await gsReference.getDownloadURL());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //Setting SystemUIOverlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiPlatformApp.create();
  }
}

class MultiPlatformApp {
  static Widget create() {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: globalProviders,
          child: OKToast(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              initialRoute: Routes.splash,
              onGenerateRoute: Pages.getPages,
              themeMode: ThemeMode.light,
              theme: ThemeData(
                fontFamily: FontFamily.pretendard,
                brightness: Brightness.light,
                progressIndicatorTheme: const ProgressIndicatorThemeData(
                  color: primary600,
                ),
                bottomSheetTheme: const BottomSheetThemeData(
                  backgroundColor: Colors.white,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ButtonStyle(
                    shadowColor: MaterialStateProperty.all(primary700),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
