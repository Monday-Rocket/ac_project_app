import 'package:ac_project_app/models/folder/folder.dart';
import 'package:equatable/equatable.dart';

class FolderList extends Equatable {

  FolderList(this.folderList);

  final List<Folder> folderList;

  @override
  List<Object?> get props => [...folderList];

  // @override
  // bool operator ==(Object other) {
  //   if (other is FolderList) {
  //     final otherFolderList = other.folderList;
  //     if (folderList.length == otherFolderList.length) {
  //       for (var i = 0; i < folderList.length; i++) {
  //         if (folderList[i] != otherFolderList[i]) {
  //           return false;
  //         }
  //       }
  //       return true;
  //     }
  //   }
  //   return false;
  // }
}
