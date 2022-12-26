import 'dart:async';

import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<LoginUserState> {
  LoginCubit() : super(LoginInitialState());

  void initialize() {
    emit(LoginInitialState());
  }

  void loading() {
    emit(LoginLoadingState());
  }

  void showError(String message) {
    emit(LoginErrorState(message));
  }

  void showNothing() {
    emit(LoginEmptyState());
  }

  void login(LoginType loginType, {String? email}) {
    emit(LoginLoadingState());
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

      user.when(
        success: (data) {
          // 1. 공유패널 데이터 가져오기
          ShareDataProvider.loadServerData();

          // 2. 로그인 이후 화면으로 이동
          emit(LoginLoadedState(data));
        },
        error: (msg) {
          emit(LoginErrorState(msg));
        },
      );
    } else {
      Log.e('login fail');
      emit(LoginErrorState('login fail'));
    }
  }
}
