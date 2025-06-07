import 'package:ac_project_app/cubits/folders/folder_users_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/folders/share_folder_api.dart';
import 'package:ac_project_app/provider/global_variables.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DelegateAdminCubit extends Cubit<FolderUsersState> {
  DelegateAdminCubit(int? folderId) : super(FolderUsersInitialState()) {
    emit(FolderUsersLoadingState());
    shareApi.getFolderMembers(folderId.toString()).then((result) {
      result.when(
        success: (data) {
          final admin = data.firstWhere((user) => user.id == me?.id);
          data.remove(admin);
          emit(FolderUsersLoadedState(admin, data, data.length + 1));
        },
        error: (msg) {
          emit(FolderUsersErrorState(msg));
        },
      );
    });
  }

  final ShareFolderApi shareApi = getIt();

  Future<bool> delegateAdmin(int? folderId, int? userId) async {
    final result = await shareApi.delegateFolderAdmin(folderId.toString(), userId.toString());
    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }
}
