import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:equatable/equatable.dart';

abstract class FolderUsersState extends Equatable {}

class FolderUsersInitialState extends FolderUsersState {
  @override
  List<Object> get props => [];
}

class FolderUsersLoadingState extends FolderUsersState {
  @override
  List<Object> get props => [];
}

class FolderUsersLoadedState extends FolderUsersState {
  FolderUsersLoadedState(this.admin, this.normalUsers, this.totalUsersCount);

  final DetailUser admin;
  final List<DetailUser> normalUsers; // Assuming users are represented as a list of strings
  final int totalUsersCount;

  @override
  List<Object> get props => [admin, normalUsers, totalUsersCount];
}

class FolderUsersErrorState extends FolderUsersState {
  FolderUsersErrorState(this.message);

  final String? message;

  @override
  List<Object> get props => [message ?? ''];
}
