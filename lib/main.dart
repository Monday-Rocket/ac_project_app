import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';

Future<void> main() async {
  await initSettings();
  await ShareDB.initSqflite();
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
        return BlocProvider<GetProfileInfoCubit>(
          create: (_) => GetProfileInfoCubit(),
          child: OKToast(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              initialRoute: Routes.splash,
              onGenerateRoute: Pages.getPages,
              themeMode: ThemeMode.light,
              theme: ThemeData(
                fontFamily: R_Font.PRETENDARD,
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
