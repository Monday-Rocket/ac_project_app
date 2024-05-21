import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AppPauseManager {
  final database = FirebaseDatabase.instance;

  Future<bool> getPause() async {
    return (await database.ref('pause').get()).value as bool? ?? false;
  }

  Future<String> getTitle() async {
    return (await database.ref('title').get()).value as String? ?? '';
  }

  Future<String> getDescription() async {
    return (await database.ref('description').get()).value as String? ?? '';
  }

  Future<String> getTimeText() async {
    return (await database.ref('time').get()).value as String? ?? '';
  }

  Future<void> showPopup(BuildContext context) async {
    showPausePopup(
      title: await getTitle(),
      description: await getDescription(),
      timeText: await getTimeText(),
      parentContext: context,
      callback: () {
        Navigator.pop(context);
        closeApp();
      },
    );
  }

  void closeApp() {
    FirebaseCrashlytics.instance.crash();
  }

  void showPopupIfPaused(BuildContext context) {
    getPause().then((value) {
      if (value) {
        showPopup(context);
      }
    });
  }
}
