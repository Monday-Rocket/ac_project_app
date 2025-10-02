import 'dart:collection';

import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/util/logger.dart';

class FolderApi {
  FolderApi(this._client);

  final CustomClient _client;

  Future<Result<List<Folder>>> getMyFolders() async {
    final result = await _client.getUri('/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];
        for (final data in folders as List<dynamic>) {
          var folder = Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            folder = folder.copyWith(name: '미분류', isClassified: false);
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<Result<List<Folder>>> getMyFoldersWithoutShared() async {
    final result = await _client.getUri('/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];
        for (final data in folders as List<dynamic>) {
          var folder = Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            folder = folder.copyWith(name: '미분류', isClassified: false);
          }
          if (folder.shared ?? false) {
            continue;
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<Result<List<Folder>>> getMyFoldersWithoutUnclassified() async {
    final result = await _client.getUri('/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];

        for (final data in folders as List<dynamic>) {
          final folder = Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            continue;
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<Result<List<Folder>>> getOthersFolders(int userId) async {
    final result = await _client.getUri('/users/$userId/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];

        for (final data in folders as List<dynamic>) {
          var folder = Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            folder = folder.copyWith(name: '미분류', isClassified: false);
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<bool> add(Folder folder) async {
    final result = await _client.postUri(
      '/folders',
      body: {
        'name': folder.name,
        'visible': folder.visible,
        'created_at': folder.time,
        'shared': folder.shared,
      },
    );

    return result.when(
      success: (_) => true,
      error: (_) => false,
    );
  }

  Future<bool> bulkSave() async {
    final newLinks = await ShareDataProvider.getNewLinks();
    final newFolders = await ShareDataProvider.getNewFolders();

    if (newLinks.isEmpty && newFolders.isEmpty) {
      return true;
    }

    final body = {
      'new_links': newLinks,
      'new_folders': newFolders,
    };

    final result = await _client.postUri('/bulk', body: body);
    return result.when(
      success: (_) {
        Log.i('bulk save success');
        ShareDataProvider.clearLinksAndFolders();
        return true;
      },
      error: (message) {
        Log.e('bulk save error: $message');
        return false;
      },
    );
  }

  Future<bool> deleteFolder(Folder folder) async {
    final result = await _client.deleteUri('/folders/${folder.id}');
    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }

  Future<bool> patchFolder(int id, Map<String, dynamic> body) async {
    final result = await _client.patchUri(
      '/folders/$id',
      body: body,
    );

    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }

  Future<bool> changeVisible(Folder folder) async {
    final result = await _client.patchUri(
      '/folders/${folder.id}',
      body: {
        'visible': !folder.visible!,
      },
    );

    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }
}
