import 'dart:collection';

import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/util/logger.dart';

class FolderApi {
  final client = CustomClient();

  Future<Result<Folder>> postFolders(List<String> folderNames) async {
    final body = <Map<String, dynamic>>[];

    for (final name in folderNames) {
      body.add({
        'name': name,
      });
    }

    final result = await client.postUri(
      '/folders',
      body: folderNames,
    );
    return result.when(
      success: (data) => Result.success(
        Folder.fromJson(data as Map<String, dynamic>),
      ),
      error: Result.error,
    );
  }

  Future<Result<List<Folder>>> getMyFolders() async {
    final result = await client.getUri('/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];

        for (final data in folders as List<dynamic>) {
          final folder =
              Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            folder
              ..name = '미분류'
              ..isClassified = false;
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<Result<List<Map<String, dynamic>>>> getFoldersForSharePanel() async {
    final result = await client.getUri('/folders');
    return result.when(
      success: (folders) {
        final list = <Map<String, dynamic>>[];

        for (final data in folders as List<dynamic>) {
          final folder = Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            continue;
          }

          list.add(folder.toJson());
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<Result<List<Folder>>> getMyFoldersWithoutUnclassified() async {
    final result = await client.getUri('/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];

        for (final data in folders as List<dynamic>) {
          final folder =
          Folder.fromJson(data as LinkedHashMap<String, dynamic>);
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
    final result = await client.getUri('/users/$userId/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];

        for (final data in folders as List<dynamic>) {
          final folder =
          Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            folder
              ..name = '미분류'
              ..isClassified = false;
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<bool> add(Folder folder) async {
    final result = await client.postUri(
      '/folders',
      body: {
        'name': folder.name,
        'visible': folder.visible,
        'created_at': folder.time,
      },
    );

    return result.when(
      success: (_) => true,
      error: (_) => false,
    );
  }

  Future<void> bulkSave() async {
    final newLinks = await ShareDataProvider.getNewLinks();
    final newFolders = await ShareDataProvider.getNewFolders();

    if (newLinks.isEmpty && newFolders.isEmpty) {
      return;
    }

    final body = {
      'new_links': newLinks,
      'new_folders': newFolders,
    };

    final result = await client.postUri('/bulk', body: body);
    result.when(
      success: (_) {
        Log.i('bulk save success');
        ShareDataProvider.clearLinksAndFolders();
      },
      error: Result.error,
    );
  }

  Future<bool> deleteFolder(Folder folder) async {
    final result = await client.deleteUri('/folders/${folder.id}');
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
    final result = await client.patchUri(
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

  Future<Result<List<Folder>>> getSelectedUserFolders(int userId) async {
    final result = await client.getUri('/users/$userId/folders');
    return result.when(
      success: (folders) {
        final list = <Folder>[];

        for (final data in folders as List<dynamic>) {
          final folder =
          Folder.fromJson(data as LinkedHashMap<String, dynamic>);
          if (folder.name == 'unclassified') {
            folder
              ..name = '미분류'
              ..isClassified = false;
          }
          list.add(folder);
        }

        return Result.success(list);
      },
      error: Result.error,
    );
  }
}
