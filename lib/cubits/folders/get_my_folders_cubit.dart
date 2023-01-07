import 'dart:async';

import 'package:ac_project_app/const/enums.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit({bool? excludeUnclassified}) : super(FoldersState.initial()) {
    if (excludeUnclassified ?? false) {
      getFoldersWithoutUnclassified();
    } else {
      getFolders();
    }
  }

  List<Folder> folders = [];

  final FolderApi folderApi = FolderApi();

  Future<void> getFolders() async {
    try {
      emit(state.copyWith(status: CommonStatus.loading));

      final result = await folderApi.getMyFolders();
      result.when(
        success: (list) {
          folders = list;
          emit(state.copyWith(status: CommonStatus.loaded, folders: folders));
        },
        error: (msg) =>
            emit(state.copyWith(status: CommonStatus.error, error: msg)),
      );
    } catch (e) {
      emit(state.copyWith(status: CommonStatus.error, error: e.toString()));
    }
  }

  Future<void> getFoldersWithoutUnclassified() async {
    try {
      emit(state.copyWith(status: CommonStatus.loading));

      final result = await folderApi.getMyFoldersWithoutUnclassified();
      result.when(
        success: (list) {
          folders = list;
          emit(state.copyWith(status: CommonStatus.loaded, folders: folders));
        },
        error: (msg) =>
            emit(state.copyWith(status: CommonStatus.error, error: msg)),
      );
    } catch (e) {
      emit(state.copyWith(status: CommonStatus.error, error: e.toString()));
    }
  }

  Future<bool> transferVisible(Folder folder) async {
    final result = await folderApi.changeVisible(folder);
    await ShareDB.changeVisible(folder);
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
      emit(state.copyWith(status: CommonStatus.loaded, folders: folders));
      return;
    } else {
      final filtered = <Folder>[];

      for (final folder in folders) {
        if (folder.name?.contains(name) ?? false) {
          filtered.add(folder);
        }
      }

      emit(state.copyWith(status: CommonStatus.loaded, folders: filtered));
    }
  }
}
