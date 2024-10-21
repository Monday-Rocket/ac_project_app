import 'package:ac_project_app/models/linkpool_pick/linkpool_pick.dart';
import 'package:equatable/equatable.dart';

abstract class LinkpoolPickResultState extends Equatable {}

class LinkpoolPickResultInitialState extends LinkpoolPickResultState {
  @override
  List<Object> get props => [];
}

class LinkpoolPickResultLoadingState extends LinkpoolPickResultState {
  @override
  List<Object> get props => [];
}

class LinkpoolPickResultLoadedState extends LinkpoolPickResultState {
  LinkpoolPickResultLoadedState(this.linkpoolPicks);

  final List<LinkpoolPick> linkpoolPicks;

  @override
  List<Object> get props => linkpoolPicks;
}

class LinkpoolPickResultErrorState extends LinkpoolPickResultState {
  LinkpoolPickResultErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

class LinkpoolPickResultNoDataState extends LinkpoolPickResultState {
  @override
  List<Object> get props => [];
}
