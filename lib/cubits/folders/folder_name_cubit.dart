import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderNameCubit extends Cubit<String> {
  FolderNameCubit(): super('');

  void update(String name) {
    emit(name);
  }

  FolderApi folderApi = FolderApi();

  Future<bool> add(Folder folder) async {
    if (await folderApi.add(folder)) {
      return ShareDB.insert(folder);
    }
    return false;
  }
}
