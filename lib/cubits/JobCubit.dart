import 'package:flutter_bloc/flutter_bloc.dart';


class JobCubit extends Cubit<String?>{
  JobCubit(super.initialState);

  void updateJob(String? state) {
    emit(state);
  }

  String? getJob() => state;
}