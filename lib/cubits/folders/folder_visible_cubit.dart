import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderVisibleCubit extends Cubit<FolderVisibleState> {
  FolderVisibleCubit(): super(FolderVisibleState.visible);

  void toggle() {
    emit(state.toggle());
  }
}
