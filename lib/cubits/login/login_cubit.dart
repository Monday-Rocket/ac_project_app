import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/user_state.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<UserState> {
  LoginCubit() : super(InitialState());

  void initialize() {
    emit(InitialState());
  }

  void login(LoginType loginType) {
    emit(LoadingState());
    switch (loginType) {
      case LoginType.google:
        Google.login().then(sendResult);
        break;
      case LoginType.apple:
        Apple.login().then(sendResult);
        break;
    }
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> sendResult(bool isSuccess) async {
    if (isSuccess) {
      final user = await UserApi().postUsers();
      final folderApi = FolderApi();

      user.when(
        success: (data) {
          folderApi.bulkSave();
          emit(LoadedState(data));
        },
        error: (msg) {
          emit(ErrorState(msg));
        },
      );
    } else {
      Log.e('login fail');
      emit(ErrorState('login fail'));
    }
  }
}
