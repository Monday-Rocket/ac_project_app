import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';

Future<void> main() async {
  await initSettings();
  await ShareDB.initSqflite();
  locator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return ScreenUtilInit(
      designSize: Size(width, height),
      minTextAdapt: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return OKToast(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            initialRoute: Routes.splash,
            onGenerateRoute: Pages.getPages,
            themeMode: ThemeMode.light,
            theme: ThemeData(
              fontFamily: FontFamily.pretendard,
              brightness: Brightness.light,
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
              progressIndicatorTheme: const ProgressIndicatorThemeData(
                color: primary600,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  shadowColor: WidgetStateProperty.all(primary700),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
