import 'package:ac_project_app/models/profile/profile.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {}

class ProfileInitialState extends ProfileState {
  @override
  List<Object> get props => [];
}

class ProfileLoadingState extends ProfileState {
  @override
  List<Object> get props => [];
}

class ProfileLoadedState extends ProfileState {
  ProfileLoadedState(this.profile);

  final Profile profile;

  @override
  List<Object> get props => [profile];
}

class ProfileErrorState extends ProfileState {
  ProfileErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
