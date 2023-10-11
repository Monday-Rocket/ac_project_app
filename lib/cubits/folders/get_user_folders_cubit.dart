import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder_list.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetUserFoldersCubit extends Cubit<FolderList> {
  GetUserFoldersCubit(): super(const FolderList([]));

  final FolderApi folderApi = getIt();

  Future<void> getFolders(int userId) async {
    try {
      final result = await folderApi.getOthersFolders(userId);
      result.when(
        success: (list) {
          emit(FolderList(list));
        },
        error: (msg) {
          emit(const FolderList([]));
        },
      );
    } catch (e) {
      emit(const FolderList([]));
    }
  }
}
