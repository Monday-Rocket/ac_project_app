import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderNameCubit extends Cubit<String> {
  FolderNameCubit(): super('');

  void update(String name) {
    emit(name);
  }

  final LocalFolderRepository _localFolderRepository = getIt();

  Future<bool> add(Folder folder) async {
    final now = DateTime.now().toIso8601String();
    final localFolder = LocalFolder(
      name: folder.name ?? '',
      createdAt: now,
      updatedAt: now,
    );
    final id = await _localFolderRepository.createFolder(localFolder);
    if (id > 0) {
      return ShareDB.insert(folder);
    }
    return false;
  }
}
