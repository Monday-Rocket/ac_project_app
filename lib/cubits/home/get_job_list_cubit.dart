import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetJobListCubit extends Cubit<JobListState> {
  GetJobListCubit() : super(InitialState()) {
    getJobList();
  }

  final userApi = UserApi();

  Future<void> getJobList() async {
    emit(LoadingState());

    final result = await userApi.getJobGroups();
    result.when(
      success: (List<JobGroup> jobs) {
        emit(LoadedState(jobs));
      },
      error: (msg) {
        emit(ErrorState(msg));
      },
    );
  }
}
