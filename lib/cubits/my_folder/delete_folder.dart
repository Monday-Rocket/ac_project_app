import 'package:ac_project_app/models/folder/folder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteFolderCubit extends Cubit<int> {
  DeleteFolderCubit() : super(0);

  Future<void> delete(Folder folder) async {}
}
