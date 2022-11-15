import 'package:ac_project_app/models/folder/folder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferFolderVisibleCubit extends Cubit<int> {
  TransferFolderVisibleCubit() : super(0);

  Future<void> change(Folder folder) async {}
}
