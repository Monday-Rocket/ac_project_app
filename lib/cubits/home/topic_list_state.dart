import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:equatable/equatable.dart';

abstract class JobListState extends Equatable {}

class InitialState extends JobListState {
  @override
  List<Object> get props => [];
}

class LoadingState extends JobListState {
  @override
  List<Object> get props => [];
}

class LoadedState extends JobListState {
  LoadedState(this.jobs);

  final List<JobGroup> jobs;

  @override
  List<Object> get props => [jobs];
}

class ErrorState extends JobListState {
  ErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
