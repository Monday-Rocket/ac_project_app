import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:equatable/equatable.dart';

abstract class FolderDrillDownState extends Equatable {
  const FolderDrillDownState();
}

class FolderDrillDownInitial extends FolderDrillDownState {
  @override
  List<Object?> get props => [];
}

class FolderDrillDownLoading extends FolderDrillDownState {
  @override
  List<Object?> get props => [];
}

class FolderDrillDownLoaded extends FolderDrillDownState {
  const FolderDrillDownLoaded({
    required this.breadcrumb,
    required this.childFolders,
    required this.directLinks,
  });

  /// 루트 → 현재 폴더까지의 경로. 마지막 원소가 현재 폴더.
  final List<Folder> breadcrumb;
  final List<Folder> childFolders;
  final List<Link> directLinks;

  Folder? get currentFolder =>
      breadcrumb.isEmpty ? null : breadcrumb.last;

  @override
  List<Object?> get props => [breadcrumb, childFolders, directLinks];
}

class FolderDrillDownError extends FolderDrillDownState {
  const FolderDrillDownError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
