import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AutoLoginCubit extends Cubit<LoginUserState> {
  AutoLoginCubit() : super(LoginInitialState());

  void userCheck() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      getIt<UserApi>().postUsers().then((result) {
        result.when(
          success: (data) {
            if (data.is_new ?? false) {
              emit(LoginInitialState());
            } else {
              ShareDataProvider.loadServerDataAtFirst();
              emit(LoginLoadedState(data));
            }
          },
          error: (_) => emit(LoginInitialState()),
        );
      });
    }
  }
}
