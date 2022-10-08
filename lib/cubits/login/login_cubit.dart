import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<User?> {
  LoginCubit(super.initialState);

  void initialize() {
    emit(null);
  }

  void login(LoginType loginType) {
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
        success: emit,
        error: Log.e,
      );
    } else {
      // TODO 실패 화면 띄워야 함
      Log.e('login fail');
    }
  }
}
