import 'dart:async';

import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit({bool? excludeUnclassified}) : super(FolderInitialState()) {
    if (excludeUnclassified ?? false) {
      getFoldersWithoutUnclassified();
    } else {
      getFolders();
    }
  }

  List<Folder> folders = [];

  final FolderApi folderApi = getIt();

  Future<void> getFolders() async {
    try {
      emit(FolderLoadingState());

      (await folderApi.getMyFolders()).when(
        success: (list) {
          folders = list;
          emit(FolderLoadedState(folders));
        },
        error: (msg) => emit(FolderErrorState(msg)),
      );
    } catch (e) {
      emit(FolderErrorState(e.toString()));
    }
  }

  Future<void> getFoldersWithoutUnclassified() async {
    try {
      emit(FolderLoadingState());

      (await folderApi.getMyFoldersWithoutUnclassified()).when(
        success: (list) {
          folders = list;
          emit(FolderLoadedState(folders));
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

  void filter(String name) {
    if (name.isEmpty) {
      emit(FolderLoadedState(folders));
    } else {
      final filtered = <Folder>[];

      for (final folder in folders) {
        if (folder.name?.contains(name) ?? false) {
          filtered.add(folder);
        }
      }

      emit(FolderLoadedState(filtered));
    }
  }
}
