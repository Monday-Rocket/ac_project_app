import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobListCubit extends Cubit<List<JobGroup>> {
  JobListCubit() : super([]) {
    getJobList();
  }

  final _userApi = getIt<UserApi>();

  Future<void> getJobList() async {
    final jobs = await _userApi.getJobGroups();
    jobs.when(success: emit, error: (msg) => emit([]));
  }
}
