import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AutoLoginCubit extends Cubit<LoginUserState> {
  AutoLoginCubit() : super(LoginInitialState());

  Future<void> userCheck() async {

    final database = FirebaseDatabase.instance;
    final pause = (await getPauseFlag(database)).value as bool? ?? false;
    final title = (await getTitle(database)).value as String? ?? '';
    final description = (await getDescription(database)).value as String? ?? '';

    if (pause) {
      emit(InspectionState(title, description));
    } else {
      _userCheck();
    }
  }

  Future<DataSnapshot> getPauseFlag(FirebaseDatabase database) {
    return database.ref('pause').get();
  }

  Future<DataSnapshot> getTitle(FirebaseDatabase database) {
    return database.ref('title').get();
  }

  Future<DataSnapshot> getDescription(FirebaseDatabase database) {
    return database.ref('description').get();
  }

  void _userCheck() {
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
