import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewCubit extends Cubit<int> {
  HomeViewCubit() : super(2) {
    folderApi.bulkSave();
  }

  FolderApi folderApi = FolderApi();

  final myFolderKey = GlobalKey<NavigatorState>();

  void moveTo(int i) {
    emit(i);
  }
}
