import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpCubit extends Cubit<String?> {
  SignUpCubit(super.initialState);

  final UserApi _userApi = UserApi();

  Future<Result<String>> signUp({User? user, String? nickname, JobGroup? job}) async {
    Log.i(user?.toJson());
    Log.i('nickname: $nickname, job: ${job?.toJson()}');

    final result = await _userApi.patchUsers(
      id: user?.id,
      nickname: nickname,
      jobGroupId: job?.id,
    );
    return result.when(
      success: (data) {
        if (data.id == user?.id) {
          return const Result.success(Routes.home);
        }
        return const Result.error('id 다름');
      },
      error: Result.error,
    );
  }
}
