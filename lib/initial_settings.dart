import 'dart:async';

import 'package:ac_project_app/firebase_options.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initSettings() async {
  WidgetsFlutterBinding.ensureInitialized();
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
