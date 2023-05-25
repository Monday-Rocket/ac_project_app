import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedViewCubit extends Cubit<List<Link>> {
  FeedViewCubit(List<Folder> folders) : super([]) {
    emit([]);
    globalFolders.addAll(folders);
    if (folders.isNotEmpty) {
      getLinks(0, page);
    }
  }

  final LinkApi linkApi = getIt();
  final hasMore = HasMoreCubit();
  final globalFolders = <Folder>[];

  int currentIndex = 0;
  int page = 0;
  final totalLinks = <Link>[];
  bool hasRefresh = false;
  final scrollController = ScrollController();

  Future<void> getLinks(int index, int pageNum) async {
    hasRefresh = false;
    currentIndex = index;

    final folder = globalFolders[index];
    final result = await linkApi.getLinksFromSelectedFolder(folder, pageNum);
    result.when(
      success: (data) {
        final links = _setScrollState(data);
        emit(links);
      },
      error: (msg) {

      },
    );
  }

  void refresh() {
    totalLinks.clear();
    hasRefresh = true;
    getLinks(currentIndex, 0);
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      getLinks(currentIndex, page + 1);
    }
  }

  Future<void> selectFolder(int index) async {
    emit([]);
    await getLinks(index, 0);
  }

  List<Link> _setScrollState(SearchedLinks data) {
    page = data.pageNum ?? 0;
    final hasPage = data.hasMorePage();
    hasMore.emit(hasPage ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }
}
