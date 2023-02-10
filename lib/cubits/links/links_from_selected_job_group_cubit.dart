import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/page_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedJobGroupCubit extends Cubit<List<Link>> {
  LinksFromSelectedJobGroupCubit() : super([]) {
    initialize();
  }

  final linkApi = LinkApi();

  HasMoreCubit hasMore = HasMoreCubit();
  int selectedJobId = 1;
  int page = 0;
  bool hasRefresh = false;
  List<Link> totalLinks = [];
  bool hasLoadMore = false;
  final scrollController = ScrollController();

  void initialize() {
    emit([]);
    getSelectedJobLinks(0, 0);
  }

  Future<void> getSelectedJobLinks(int jobGroupId, int pageNum, {bool hasLoadMore = false}) async {
    hasRefresh = false;
    selectedJobId = jobGroupId;
    if (hasLoadMore) {
      await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    }
    final result = await linkApi.getJobGroupLinks(jobGroupId, pageNum);
    result.when(
      success: (data) {
        final links = _setScrollState(data);
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
    getSelectedJobLinks(selectedJobId, 0);
  }

  bool loadMore() {
    emit([]);
    hasLoadMore = hasMore.state == ScrollableType.can;
    if (hasLoadMore) {
      getSelectedJobLinks(selectedJobId, page + 1, hasLoadMore: hasLoadMore);
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
    hasLoadMore = hasMorePage(data);
    hasMore.emit(hasLoadMore ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }
}
