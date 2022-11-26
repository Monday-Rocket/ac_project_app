import 'package:ac_project_app/models/link/link.dart';
import 'package:equatable/equatable.dart';

abstract class LinkListState extends Equatable {}

class LinkListInitialState extends LinkListState {
  @override
  List<Object> get props => [];
}

class LinkListLoadingState extends LinkListState {

  @override
  List<Object> get props => [];
}

class LinkListLoadedState extends LinkListState {
  LinkListLoadedState(this.links);

  final List<Link> links;

  @override
  List<Object> get props => [links];
}

class LinkListErrorState extends LinkListState {
  LinkListErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
