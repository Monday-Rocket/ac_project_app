import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetUserFoldersCubit extends Cubit<List<Folder>> {
  GetUserFoldersCubit(): super([]);

  List<Folder> folders = [];

  final FolderApi folderApi = getIt();

  Future<List<Folder>> getFolders(int userId) async {
    try {
      final result = await folderApi.getOthersFolders(userId);
      return result.when(
        success: (list) {
          return list;
        },
        error: (msg) {
          return [];
        },
      );
    } catch (e) {
      return [];
    }
  }
}
