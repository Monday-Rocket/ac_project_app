import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewCubit extends Cubit<int> {

  FolderApi api = FolderApi();

  HomeViewCubit(): super(2) {
    api.bulkSave();
  }

  void moveTo(int i) {
    emit(i);
  }
}
