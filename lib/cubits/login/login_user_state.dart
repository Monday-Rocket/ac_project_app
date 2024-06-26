import 'package:ac_project_app/models/user/user.dart';
import 'package:equatable/equatable.dart';

abstract class LoginUserState extends Equatable {}

class LoginInitialState extends LoginUserState {
  @override
  List<Object> get props => [];
}

class LoginLoadingState extends LoginUserState {
  @override
  List<Object> get props => [];
}

class LoginLoadedState extends LoginUserState {
  LoginLoadedState(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}

class InspectionState extends LoginUserState {
  InspectionState(this.title, this.description, this.timeText);
  
  final String title;
  final String description;
  final String timeText;
  
  @override
  List<Object> get props => [title, description, timeText];
}

class LoginErrorState extends LoginUserState {
  LoginErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

class LoginEmptyState extends LoginUserState {
  @override
  List<Object> get props => [];
}
