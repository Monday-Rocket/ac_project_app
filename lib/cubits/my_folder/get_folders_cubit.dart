import 'package:ac_project_app/cubits/my_folder/folders_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit(): super(InitialState()) {
    getFolders();
  }

  final FolderApi folderApi = FolderApi();


  Future<void> getFolders() async {
    try {
      emit(LoadingState());

      // api에서 조회
      final folders = [
        Folder(
          name: '미분류',
          private: true,
          linkCount: 20,
        ),
        Folder(
          imageUrl:
          'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
          name: '디자인',
          private: true,
          linkCount: 30,
        ),
        Folder(
          imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1667px-Apple_logo_black.svg.png',
          name: 'Apple',
          private: false,
          linkCount: 12345,
        ),
      ];

      emit(LoadedState(folders));
    } catch (e) {
      emit(ErrorState());
    }
  }
}
