import 'dart:async';

import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initSettings() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  );

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
