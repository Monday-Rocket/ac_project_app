import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddNewFolderCubit extends Cubit<int> {
  AddNewFolderCubit() : super(0);

  FolderApi folderApi = FolderApi();

  Future<void> add(Folder folder) async {
    await folderApi.add(folder);
    await ShareDB.insert(folder);
  }
}
