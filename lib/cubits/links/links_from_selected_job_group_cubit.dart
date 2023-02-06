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
  final scrollController = ScrollController();

  void initialize() {
    emit([]);
    getSelectedJobLinks(0, 0);
  }

  Future<void> getSelectedJobLinks(int jobGroupId, int pageNum) async {
    hasRefresh = false;
    selectedJobId = jobGroupId;
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

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      getSelectedJobLinks(selectedJobId, page + 1);
    }
  }

  List<Link> _setScrollState(SearchedLinks data) {
    page = data.pageNum ?? 0;
    final hasPage = hasMorePage(data);
    hasMore.emit(hasPage ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }
}
