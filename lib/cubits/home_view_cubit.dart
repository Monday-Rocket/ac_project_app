import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewCubit extends Cubit<int> {
  HomeViewCubit() : super(0) {
    folderApi.bulkSave();
  }

  FolderApi folderApi = FolderApi();

  void moveTo(int i) {
    emit(i);
  }
}
