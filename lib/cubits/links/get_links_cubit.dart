import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetLinksCubit extends Cubit<List<Link>> {
  GetLinksCubit() : super([]) {
    initialize();
  }

  final LinkApi linkApi = getIt();

  HasMoreCubit hasMore = HasMoreCubit();
  int page = 0;
  bool hasRefresh = false;
  List<Link> totalLinks = [];
  bool hasLoadMore = false;
  final scrollController = ScrollController();

  void initialize() {
    emit([]);
    getLinks(0);
  }

  Future<void> getLinks(int pageNum) async {
    hasRefresh = false;
    final result = await linkApi.getLinks(pageNum);
    result.when(
      success: (data) {
        final links = _setScrollState(data);
        totalLinks.addAll(links);
        emit(links);
      },
      error: (msg) {},
    );
  }

  void clear() {
    totalLinks.clear();
    hasRefresh = true;
  }

  void refresh() {
    totalLinks.clear();
    hasRefresh = true;
    getLinks(0);
  }

  bool loadMore() {
    emit([]);
    hasLoadMore = hasMore.state == ScrollableType.can;
    if (hasLoadMore) {
      getLinks(page + 1);
    }
    return hasLoadMore;
  }

  void scrollEnd() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  List<Link> _setScrollState(SearchedLinks data) {
    page = data.pageNum ?? 0;
    hasLoadMore = data.hasMorePage();
    hasMore.emit(hasLoadMore ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }
}
