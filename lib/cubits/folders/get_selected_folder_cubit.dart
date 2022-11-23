import 'package:ac_project_app/models/folder/folder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetSelectedFolderCubit extends Cubit<Folder> {
  GetSelectedFolderCubit(super.initialState);

  void update(Folder folder) {
    emit(folder);
  }
}
