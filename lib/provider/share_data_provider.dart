import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ShareDataProvider {
  static const _platform = MethodChannel('share_data_provider');

  static Future<List<Map<String, dynamic>>> getNewLinks() async {
    try {
      final newLinks = await _platform.invokeMethod('getNewLinks')
          as LinkedHashMap<Object?, Object?>;

      final links = <Map<String, dynamic>>[];
      for (final url in newLinks.keys) {
        final item =
            jsonDecode(newLinks[url].toString()) as Map<String, dynamic>;
        Log.i(item);
        final decoded = decodeBase64Text(item['title'] as String? ?? '');
        final shortTitle = getShortTitle(decoded);
        links.add({
          'url': url,
          'title': shortTitle,
          'describe': item['comment'],
          'image': item['image_link'],
          'folder_name': item['folder_name'],
          'created_at': item['created_at'],
        });
      }

      return links;
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getNewFolders() async {
    try {
      final newFolders =
          await _platform.invokeMethod('getNewFolders') as List<Object?>? ?? [];

      final result = <Map<String, dynamic>>[];

      for (final temp in newFolders) {
        final json = jsonDecode(temp!.toString()) as Map<String, dynamic>;
        final folder = {
          'name': json['name'],
          'visible': json['visible'],
          'created_at': json['created_at'],
        };
        result.add(folder);
      }

      return result;
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }

  static Future<void> clearLinksAndFolders() async {
    try {
      final result = await _platform.invokeMethod('clearData');
      Log.i('bulk save clear data result: $result');
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

  static Future<void> clearAllData() async {
    try {
      final result = await _platform.invokeMethod('clearData');
      await ShareDB.deleteAllFolder();
      Log.i('clear all data: $result');
    } catch (e) {
      Log.e('shared preference 데이터 비우기 실패: $e');
    }
  }

  static void loadServerData() {
    try {
      getIt<FolderApi>().getMyFoldersWithoutUnclassified().then(
            (result) => result.when(
              success: (folders) {
                ShareDB.loadData(folders)
                    .then((result) => Log.i('load all data: $result'));
              },
              error: Log.e,
            ),
          );
    } on PlatformException catch (e) {
      Log.e(e.message);
    }
  }

  static void loadServerDataAtFirst() {
    SharedPrefHelper.getValueFromKey<bool>('isFirst', defaultValue: false).then((isFirst) {
      if (isFirst) {
        loadServerData();
        SharedPrefHelper.saveKeyValue('isFirst', false);
      }
    });
  }
}
