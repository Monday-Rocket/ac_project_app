import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/provider/global_providers.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    //Setting SystemUIOverlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      useInheritedMediaQuery: true,
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
