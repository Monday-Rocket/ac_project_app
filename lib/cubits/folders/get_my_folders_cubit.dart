import 'dart:async';

import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit({bool? excludeUnclassified, bool? excludeSharedLinks}) : super(FolderInitialState()) {
    if (excludeUnclassified ?? false) {
      getFoldersWithoutUnclassified();
    } else if (excludeSharedLinks ?? false) {

    } else {
      getFolders(isFirst: true);
    }
  }

  List<Folder> folders = [];

  final FolderApi folderApi = getIt();

  Future<void> getFolders({bool? isFirst}) async {
    try {
      emit(FolderLoadingState());

      (await folderApi.getMyFolders()).when(
        success: (list) async {
          folders = list;

          final totalLinksText = '${getTotalLinksCount()}';
          final addedLinksCount = await getAddedLinksCount();
          if (isFirst ?? false) {
            await SharedPrefHelper.saveKeyValue('savedLinksCount', getTotalLinksCount());
          }

          emit(FolderLoadedState(folders, totalLinksText, addedLinksCount));
        },
        error: (msg) => emit(FolderErrorState(msg)),
      );
    } catch (e) {
      emit(FolderErrorState(e.toString()));
    }
  }

  int getTotalLinksCount() {
    return folders.fold<int>(
      0,
      (previousValue, element) => previousValue + (element.links ?? 0),
    );
  }

  Future<void> getFoldersWithoutUnclassified() async {
    try {
      emit(FolderLoadingState());

      (await folderApi.getMyFoldersWithoutUnclassified()).when(
        success: (list) async {
          folders = list;
          final totalLinksText = '${getTotalLinksCount()}';
          final addedLinksCount = await getAddedLinksCount();
          emit(FolderLoadedState(folders, totalLinksText, addedLinksCount));
        },
        error: (msg) => emit(FolderErrorState(msg)),
      );
    } catch (e) {
      emit(FolderErrorState(e.toString()));
    }
  }

  Future<bool> transferVisible(Folder folder) async {
    final result = await folderApi.changeVisible(folder);
    await ShareDB.changeVisible(folder);
    unawaited(getFolders());
    return result;
  }

  Future<bool> changeName(Folder folder, String name) async {
    final result = await folderApi.patchFolder(folder.id!, {'name': name});
    await ShareDB.changeName(folder, name);
    unawaited(getFolders());
    return result;
  }

  Future<bool> delete(Folder folder) async {
    final result = await folderApi.deleteFolder(folder);
    await ShareDB.deleteFolder(folder);
    unawaited(getFolders());
    return result;
  }

  Future<void> filter(String name) async {
    final totalLinksText = '${getTotalLinksCount()}';
    final addedLinksCount = await getAddedLinksCount();
    if (name.isEmpty) {
      emit(FolderLoadedState(folders, totalLinksText, addedLinksCount));
    } else {
      final filtered = folders.where((folder) => folder.name?.contains(name) ?? false).toList();
      emit(FolderLoadedState(filtered, totalLinksText, addedLinksCount));
    }
  }

  Future<int> getAddedLinksCount() async => getTotalLinksCount() - await SharedPrefHelper.getValueFromKey<int>('savedLinksCount', defaultValue: 0);
}
