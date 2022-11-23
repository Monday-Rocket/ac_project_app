import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedFolderCubit extends Cubit<LinkListState> {
  LinksFromSelectedFolderCubit(Folder folder, int pageNum)
      : super(LinkListInitialState()) {
    getSelectedLinks(folder, pageNum);
  }

  final linkApi = LinkApi();

  Future<void> getSelectedLinks(Folder folder, int pageNum) async {
    emit(LinkListLoadingState());

    if (folder.isClassified ?? true) {
      final result = await linkApi.getLinksFromSelectedFolder(folder, pageNum);
      result.when(
        success: (links) {
          emit(LinkListLoadedState(links.contents ?? []));
        },
        error: (msg) {
          emit(LinkListErrorState(msg));
        },
      );
    } else {
      final result = await linkApi.getUnClassifiedLinks(pageNum);
      result.when(
        success: (links) {
          emit(LinkListLoadedState(links.contents ?? []));
        },
        error: (msg) {
          emit(LinkListErrorState(msg));
        },
      );
    }
  }
}
