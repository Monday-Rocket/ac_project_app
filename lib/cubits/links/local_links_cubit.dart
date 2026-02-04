import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_model_extensions.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB를 사용하는 링크 Cubit
/// GetLinksCubit을 대체
class LocalLinksCubit extends Cubit<List<Link>> {
  LocalLinksCubit() : super([]) {
    initialize();
  }

  final LocalLinkRepository _linkRepository = getIt();

  HasMoreCubit hasMore = HasMoreCubit();
  int page = 0;
  bool hasRefresh = false;
  List<Link> totalLinks = [];
  bool hasLoadMore = false;
  final scrollController = ScrollController();

  static const int _pageSize = 20;

  void initialize() {
    emit([]);
    getLinks(0);
  }

  Future<void> getLinks(int pageNum) async {
    try {
      hasRefresh = false;
      page = pageNum;

      final localLinks = await _linkRepository.getAllLinks(
        limit: _pageSize,
        offset: pageNum * _pageSize,
      );

      final links = localLinks.toLinkList();

      // 더 있는지 확인
      final totalCount = await _linkRepository.getTotalLinkCount();
      final hasMorePages = (pageNum + 1) * _pageSize < totalCount;
      hasMore.emit(hasMorePages ? ScrollableType.can : ScrollableType.cannot);
      hasLoadMore = hasMorePages;

      totalLinks.addAll(links);
      emit(links);
    } catch (e) {
      Log.e('LocalLinksCubit.getLinks error: $e');
    }
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
}
