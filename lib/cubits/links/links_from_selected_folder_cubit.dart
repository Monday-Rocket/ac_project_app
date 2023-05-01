import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedFolderCubit extends Cubit<LinkListState> {
  LinksFromSelectedFolderCubit(Folder folder, int pageNum)
      : super(LinkListInitialState()) {
    getSelectedLinks(folder, pageNum);
  }

  final linkApi = LinkApi();

  HasMoreCubit hasMore = HasMoreCubit();
  Folder? currentFolder;
  int page = 0;
  int totalCount = 0;

  Future<void> getSelectedLinks(Folder folder, int pageNum) async {
    emit(LinkListLoadingState());

    currentFolder = folder;

    if (folder.isClassified ?? true) {
      final result = await linkApi.getLinksFromSelectedFolder(folder, pageNum);
      result.when(
        success: (data) {
          totalCount = data.totalCount ?? 0;
          final links = _setScrollState(data);
          emit(LinkListLoadedState(links));
        },
        error: (msg) {
          emit(LinkListErrorState(msg));
        },
      );
    } else {
      final result = await linkApi.getUnClassifiedLinks(pageNum);
      result.when(
        success: (data) {
          totalCount = data.totalCount ?? 0;
          final links = _setScrollState(data);
          emit(LinkListLoadedState(links));
        },
        error: (msg) {
          emit(LinkListErrorState(msg));
        },
      );
    }
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      getSelectedLinks(currentFolder!, page + 1);
    }
  }

  List<Link> _setScrollState(SearchedLinks data) {
    page = data.pageNum ?? 0;
    final hasPage = data.hasMorePage();
    hasMore.emit(hasPage ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }

  void loading() {
    emit(LinkListLoadingState());
  }
}
