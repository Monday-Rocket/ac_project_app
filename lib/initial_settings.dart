import 'dart:async';
import 'dart:ui';

import 'package:ac_project_app/firebase_options.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

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

  Future<void> saveFirstInstalled() async {
    final isFirst = await SharedPrefHelper.getValueFromKey<bool>('isFirst', defaultValue: true);
    if (isFirst) {
      unawaited(SharedPrefHelper.saveKeyValue('isFirst', true));
    }
    final tutorial = await SharedPrefHelper.getValueFromKey<bool>('tutorial2', defaultValue: true);
    if (tutorial) {
      unawaited(SharedPrefHelper.saveKeyValue('tutorial2', true));
    }
  }

  unawaited(saveFirstInstalled());
}
