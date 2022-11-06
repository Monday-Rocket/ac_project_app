import 'dart:io';

import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ShareDataProvider {
  static const _platform = MethodChannel('share_data_provider');

  static Future<List<String>> getShareDataList() async {
    try {
      final data =
      await _platform.invokeMethod('getShareData') as List<Object?>;

      final result = <String>[];

      for (final item in data) {
        result.add(item.toString());
      }

      return result;
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

