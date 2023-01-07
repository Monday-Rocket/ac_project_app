import 'package:ac_project_app/const/enums.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:equatable/equatable.dart';

class FoldersState extends Equatable {
  const FoldersState({
    required this.status,
    required this.folders,
    required this.error,
  });

  factory FoldersState.initial() {
    return const FoldersState(
      status: CommonStatus.initial,
      folders: [],
      error: '',
    );
  }

  final CommonStatus status;
  final List<Folder> folders;
  final String error;

  @override
  List<Object?> get props => [status, folders, error];

  @override
  String toString() {
    return 'FoldersState{status: $status, folders: $folders, error: $error}';
  }

  FoldersState copyWith({
    CommonStatus? status,
    List<Folder>? folders,
    String? error,
  }) {
    return FoldersState(
      status: status ?? this.status,
      folders: folders ?? this.folders,
      error: error ?? this.error,
    );
  }
}
