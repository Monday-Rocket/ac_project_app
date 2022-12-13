import 'package:ac_project_app/models/feed/feed_data.dart';
import 'package:equatable/equatable.dart';

abstract class FeedDataState extends Equatable {}

class FeedDataInitialState extends FeedDataState {
  @override
  List<Object> get props => [];
}

class FeedDataLoadingState extends FeedDataState {

  @override
  List<Object> get props => [];
}

class FeedDataLoadedState extends FeedDataState {
  FeedDataLoadedState(this.feedData);

  final FeedData feedData;

  @override
  List<Object> get props => [feedData];
}

class FeedDataErrorState extends FeedDataState {
  FeedDataErrorState(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
