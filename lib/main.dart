import 'dart:io';

import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/route_manager.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;

Future<void> main() async {
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['kakao.api.key']);
  WidgetsFlutterBinding.ensureInitialized();



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      getPages: Pages.pages,
    );
  }
}
