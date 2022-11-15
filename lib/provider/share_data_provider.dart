import 'dart:io';

import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ShareDataProvider {
  static const _platform = MethodChannel('share_data_provider');

  static Future<List<dynamic>> getNewLinks() async {
    try {
      return await _platform.invokeMethod('getNewLinks') as List<dynamic>? ??
          [];
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }

  static Future<List<dynamic>> getNewFolders() async {
    try {
      return await _platform.invokeMethod('getNewFolders') as List<dynamic>? ??
          [];
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
        return path.join(
          await _platform.invokeMethod('getShareDBUrl') as String,
          'share.db',
        );
      }
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }
}
