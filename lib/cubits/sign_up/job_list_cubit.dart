import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobListCubit extends Cubit<List<JobGroup>> {
  JobListCubit() : super([]) {
    getJobList();
    textController = TextEditingController(text: textHint);
  }

  final textHint = '직업을 선택해주세요';
  late TextEditingController textController;

  final UserApi _userApi = UserApi();

  Future<void> getJobList() async {
    final jobs = await _userApi.getJobGroups();
    jobs.when(success: emit, error: (msg) => emit([]));
  }

  TextEditingController getTextController() {
    return textController;
  }
}
