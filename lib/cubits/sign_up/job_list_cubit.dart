import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobListCubit extends Cubit<List<JobGroup>?> {
  JobListCubit(super.initialState);

  final UserApi _userApi = UserApi();

  Future<List<JobGroup>> getJobList() async {
    final jobs = await _userApi.getJobGroups();
    return jobs.when(
      success: (data) {
        return data;
      },
      error: (msg) {
        return [];
      },
    );
  }
}
