import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<String?> {
  LoginCubit(super.initialState);

  void login(LoginType loginType) {
    switch(loginType) {
      case LoginType.google:
        Google.login().then((result) {
          if (result != null) {
            emit(result);
          }
        });
        break;
      case LoginType.apple:
        Apple.login().then((result) {
          if (result != null) {
            emit(result);
          }
        });
        break;
    }
  }
}
