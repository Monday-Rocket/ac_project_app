import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ac_project_app/firebase_options.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

Future<void> main() async {
  await initSettings();
  runApp(const MyApp());
}

Future<void> initSettings() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
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
    if (Platform.isAndroid) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.login,
        onGenerateRoute: Pages.getPages,
      );
    } else {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.login,
        onGenerateRoute: Pages.getPages,
      );
    }
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
