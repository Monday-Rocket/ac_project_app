import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/models/login/login_type.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<SignUpType?> {
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
      /* TODO user가 가입을 안했으면 가입화면으로
          가입을 했으면 홈화면으로 */
      user.when(
        success: (User data) {
          if (data.isNew ?? true) {
            // 처음부터 가입
            emit(SignUpType.newUser);
          } else {
            // 이미 가입한 유저
            emit(SignUpType.signedUser);
          }
        },
        error: (msg) {
          Log.e(msg);
          // 로그인 실패 1
        },
      );
    } else {
      Log.e('error');
      // 로그인 실패 2
    }
  }
}
