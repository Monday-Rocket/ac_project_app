import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedFolderCubit extends Cubit<LinkListState> {
  LinksFromSelectedFolderCubit(Folder folder, int pageNum) : super(LinkListInitialState()) {
    getSelectedLinks(folder, pageNum);
  }

  final LinkApi linkApi = getIt();

  HasMoreCubit hasMore = HasMoreCubit();
  Folder? currentFolder;
  int page = 0;
  String searchingText = '';

  Future<void> getSelectedLinks(Folder folder, int pageNum) async {
    searchingText = '';
    emit(LinkListLoadingState());

    currentFolder = folder;

    if (folder.isClassified ?? true) {
      final result = await linkApi.getLinksFromSelectedFolder(folder, pageNum);
      result.when(
        success: (data) {
          final totalCount = data.totalCount ?? 0;
          final links = _setScrollState(data);
          emit(LinkListLoadedState(links, totalCount));
        },
        error: (msg) {
          emit(LinkListErrorState(msg));
        },
      );
    } else {
      final result = await linkApi.getUnClassifiedLinks(pageNum);
      result.when(
        success: (data) {
          final totalCount = data.totalCount ?? 0;
          final links = _setScrollState(data);
          emit(LinkListLoadedState(links, totalCount));
        },
        error: (msg) {
          emit(LinkListErrorState(msg));
        },
      );
    }
  }

  Future<void> refresh() async {
    emit(LinkListLoadingState());
    await getSelectedLinks(currentFolder!, 0);
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      if (searchingText.isNotEmpty) {
        searchLinksFromSelectedFolder(searchingText, page + 1);
      } else {
        getSelectedLinks(currentFolder!, page + 1);
      }
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

  Future<void> searchLinksFromSelectedFolder(
    String text,
    int pageNum,
  ) async {
    searchingText = text;
    emit(LinkListLoadingState());

    final result = await linkApi.searchLinksFromFolder(text, currentFolder!.id!, pageNum);
    result.when(
      success: (data) {
        final totalCount = data.totalCount ?? 0;
        final links = _setScrollState(data);
        emit(LinkListLoadedState(links, totalCount));
      },
      error: (msg) {
        emit(LinkListErrorState(msg));
      },
    );
  }
}
