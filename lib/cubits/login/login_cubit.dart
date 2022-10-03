import 'package:ac_project_app/const/token.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/provider/api/login/login_api.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<String?> {

  LoginCubit(super.initialState);

  void login(LoginType loginType) {
    switch(loginType) {
      case LoginType.google:
        Google.login().then(sendResult);
        break;
      case LoginType.apple:
        Apple.login().then(sendResult);
        break;
    }
  }

  void sendResult(String? token) {
    if (token != null) {
      globalToken = token;
      LoginApi().createUser();
      emit(token);
    }
  }
}
