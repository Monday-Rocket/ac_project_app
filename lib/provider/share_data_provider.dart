import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ShareDataProvider {
  static const _platform = MethodChannel('share_data_provider');


  static Future<void> getNewLinks() async {
    try {
      final linkList = await _platform.invokeMethod('getNewLinks') as List<Object?>;

      for (final linkData in linkList) {
        Log.i(linkData);
      }
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }

  static Future<void> getNewFolders() async {
    try {
      final folderList = await _platform.invokeMethod('getNewFolders') as List<Object?>? ?? [];

      for (final folder in folderList) {
        Log.i(folder);
      }

    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }

  static Future<String> getShareDBUrl() async {
    try {
      if (Platform.isAndroid) {
        return '${await getDatabasesPath()}/share.db';
      } else {
        return path.join(await _platform.invokeMethod('getShareDBUrl') as String, 'share.db');
      }
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }
}

