import 'package:flutter_bloc/flutter_bloc.dart';

class FolderViewTypeCubit extends Cubit<FolderViewType> {
  FolderViewTypeCubit(): super(FolderViewType.list);

  void toggle() {
    if (state == FolderViewType.list) {
      emit(FolderViewType.grid);
    } else {
      emit(FolderViewType.list);
    }
  }
}

enum FolderViewType {
  list, grid
}
