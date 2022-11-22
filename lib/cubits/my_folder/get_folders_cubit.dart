import 'package:ac_project_app/cubits/my_folder/folders_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit() : super(InitialState()) {
    getFolders();
  }

  List<Folder> folders = [];

  final FolderApi folderApi = FolderApi();

  // 데이터 변경 시 이거 호출해서 갱신하면 될 듯
  Future<void> getFolders() async {
    try {
      emit(LoadingState());

      final result = await folderApi.getMyFolders();
      result.when(
        success: (list) {
          folders = list;
          emit(LoadedState(folders));
        },
        error: (msg) => emit(ErrorState(msg)),
      );
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  void addFolder(Folder folder) {
    emit(LoadingState());
    folders.insert(1, folder);
    emit(LoadedState(folders));
  }

  List<Folder> getTotalFolders() {
    return folders;
  }

  void transferVisible(Folder folder) {}

  void deleteFolder(Folder folder) {}

  void filter(String name) {
    if (name.isEmpty) {
      emit(LoadedState(folders));
      return;
    } else {
      final filtered = <Folder>[];

      for (final folder in folders) {
        if (folder.name?.contains(name) ?? false) {
          filtered.add(folder);
        }
      }

      emit(LoadedState(filtered));
    }
  }
}
