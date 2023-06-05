import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetJobListCubit extends Cubit<JobListState> {
  GetJobListCubit() : super(InitialState()) {
    getJobList();
  }

  final UserApi userApi = getIt();

  Future<void> getJobList() async {
    emit(LoadingState());

    final result = await userApi.getJobGroups();
    result.when(
      success: (List<JobGroup> jobs) {
        jobs.insert(0, JobGroup(id: 0, name: '전체'));
        emit(LoadedState(jobs));
      },
      error: (msg) {
        emit(ErrorState(msg));
      },
    );
  }
}
