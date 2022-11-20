import 'package:ac_project_app/cubits/my_folder/folders_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit() : super(InitialState()) {
    getFolders();
  }

  List<Folder> folders = [];

  final FolderApi folderApi = FolderApi();

  // 데이터 변경 시 이거 호출해서 갱신하면 될 듯
  Future<void> getFolders() async {
    try {
      emit(LoadingState());

      // api에서 조회
      folders = [
        Folder(
          name: '미분류',
          visible: false,
          linkCount: 20,
        ),
        Folder(
          imageUrl:
              'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
          name: '디자인1',
          visible: true,
          linkCount: 30,
        ),
        Folder(
          imageUrl:
              'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
          name: '디자인2',
          visible: false,
          linkCount: 30,
        ),
        Folder(
          imageUrl:
              'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
          name: '디자인3',
          visible: true,
          linkCount: 30,
        ),
        Folder(
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1667px-Apple_logo_black.svg.png',
          name: 'Apple',
          visible: false,
          linkCount: 12345,
        ),
      ];
      // final folders = <Folder>[];

      emit(LoadedState(folders));
    } catch (e) {
      emit(ErrorState());
    }
  }

  void addFolder(Folder folder) {
    emit(LoadingState());
    folders.insert(1, folder);
    emit(LoadedState(folders));
  }

  List<Folder> getTotalFolders() {
    return folders;
  }

  void transferVisible(Folder folder) {}

  void deleteFolder(Folder folder) {}

  void filter(String name) {
    if (name.isEmpty) {
      emit(LoadedState(folders));
      return;
    } else {
      final filtered = <Folder>[];

      for (final folder in folders) {
        if (folder.name?.contains(name) ?? false) {
          filtered.add(folder);
        }
      }

      emit(LoadedState(filtered));
    }
  }
}
