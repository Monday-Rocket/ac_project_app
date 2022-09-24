import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoogleLoginCubit extends Cubit<String?> {
  GoogleLoginCubit(super.initialState);

  Future<void> login() async {
    final userCredential = await Google.login();
    final firebaseToken = userCredential?.credential?.token;
    Log.i(firebaseToken);
    if (firebaseToken != null) {
      emit(firebaseToken.toString());
    }
  }
}
