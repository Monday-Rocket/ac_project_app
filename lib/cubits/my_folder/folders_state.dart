import 'package:ac_project_app/models/folder/folder.dart';
import 'package:equatable/equatable.dart';

abstract class FoldersState extends Equatable {}

class InitialState extends FoldersState {
  @override
  List<Object> get props => [];
}
class LoadingState extends FoldersState {
  @override
  List<Object> get props => [];
}
class LoadedState extends FoldersState {
  LoadedState(this.folders);

  final List<Folder> folders;

  @override
  List<Object> get props => [folders];
}
class ErrorState extends FoldersState {
  @override
  List<Object> get props => [];
}