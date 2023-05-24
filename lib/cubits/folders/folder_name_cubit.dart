import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderNameCubit extends Cubit<String> {
  FolderNameCubit(): super('');

  void update(String name) {
    emit(name);
  }

  final folderApi = getIt<FolderApi>();

  Future<bool> add(Folder folder) async {
    if (await folderApi.add(folder)) {
      return ShareDB.insert(folder);
    }
    return false;
  }
}
