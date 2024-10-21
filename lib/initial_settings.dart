import 'dart:async';
import 'dart:ui';

import 'package:ac_project_app/firebase_options.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// https://www.youtube.com/watch?v=Akt91Cl_z00&ab_channel=%EC%98%A4%EC%A4%80%EC%84%9D%EC%9D%98%EC%83%9D%EC%A1%B4%EC%BD%94%EB%94%A9
Future<void> initSettings() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_API_KEY'],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  );
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'ac_project',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app();
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };

  _saveFirstInstalled();
}

void _saveFirstInstalled() {
  SharedPreferences.getInstance().then((SharedPreferences prefs) {
    final isFirst = prefs.getBool('isFirst') ?? true;
    if (isFirst) {
      prefs.setBool('isFirst', true);
    }
    final tutorial = prefs.getBool('tutorial2') ?? true;
    if (tutorial) {
      prefs.setBool('tutorial2', true);
    }
  });
}
