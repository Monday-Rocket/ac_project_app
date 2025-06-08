import 'package:ac_project_app/models/folder/folder.dart';
import 'package:equatable/equatable.dart';

abstract class FoldersState extends Equatable {}

class FolderInitialState extends FoldersState {
  @override
  List<Object> get props => [];
}

class FolderLoadingState extends FoldersState {
  @override
  List<Object> get props => [];
}

class FolderLoadedState extends FoldersState {
  FolderLoadedState(this.folders, this.totalLinksText, this.addedLinksCount);

  final List<Folder> folders;
  final String totalLinksText;
  final int addedLinksCount;

  @override
  List<Object> get props => folders;
}

class FolderErrorState extends FoldersState {
  FolderErrorState(this.message);

  final String? message;

  @override
  List<Object> get props => [message ?? ''];
}
