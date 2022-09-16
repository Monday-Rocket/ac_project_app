import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/route_manager.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['kakao.api.key']);
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(
    getApplicationDocumentsDirectory().then((Directory dir) {
      final basePath = '${dir.path}/share.txt';
      Log.i('basePath: $basePath');
      if (File(basePath).existsSync()) {
        Log.i(File(basePath).readAsStringSync());
      }
    }),
  );
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

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  unawaited(service.startService());
}


bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO 여기서 File 내용 바뀌는 것 확인해서 서버 업로드

  return true;
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // TODO 여기서 File 내용 바뀌는 것 확인해서 서버 업로드
}