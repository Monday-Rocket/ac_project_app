import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/local/local_bulk_repository.dart';
import 'package:ac_project_app/provider/share_db.dart';
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
          'shared': json['share_mode'],
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

  /// 네이티브 공유 패널에서 받은 데이터를 로컬 DB에 저장
  /// 기존 FolderApi.bulkSave()를 대체
  static Future<bool> bulkSaveToLocal() async {
    try {
      final newLinks = await getNewLinks();
      final newFolders = await getNewFolders();

      if (newLinks.isEmpty && newFolders.isEmpty) {
        return true;
      }

      final bulkRepository = getIt<LocalBulkRepository>();
      final result = await bulkRepository.bulkInsertFromNative(
        links: newLinks,
        folders: newFolders,
      );

      if (result.totalInserted > 0) {
        Log.i('Local bulk save success: ${result.insertedFolders} folders, ${result.insertedLinks} links');
        await clearLinksAndFolders();
      }

      return true;
    } catch (e) {
      Log.e('Local bulk save error: $e');
      return false;
    }
  }

  /// @deprecated 오프라인 모드에서는 사용하지 않음
  /// 서버 폴더 데이터를 ShareDB에 로드 (레거시)
  @Deprecated('Use OfflineMigrationService.migrateToLocal() instead')
  static void loadServerData() {
    Log.i('loadServerData is deprecated in offline mode');
  }

  /// @deprecated 오프라인 모드에서는 사용하지 않음
  @Deprecated('Use OfflineMigrationService.migrateToLocal() instead')
  static void loadServerDataAtFirst() {
    Log.i('loadServerDataAtFirst is deprecated in offline mode');
  }
}
