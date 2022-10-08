import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class JobCubit extends Cubit<JobGroup?>{
  JobCubit(super.initialState);

  void updateJob(JobGroup? state) {
    emit(state);
  }

  JobGroup? getJob() => state;
}
