import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/models/local/local_model_extensions.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB를 사용하는 검색 Cubit
/// SearchLinksCubit을 대체 (오프라인에서는 자신의 링크만 검색)
class LocalSearchLinksCubit extends Cubit<LinkListState> {
  LocalSearchLinksCubit() : super(LinkListInitialState());

  final LocalLinkRepository _linkRepository = getIt();

  HasMoreCubit hasMore = HasMoreCubit();
  int page = 0;
  String currentText = '';
  bool hasAdded = true;
  final totalLinks = <Link>[];
  List<LocalLink> _allSearchResults = [];

  static const int _pageSize = 20;

  /// 내 링크 검색 (오프라인에서는 이것만 사용)
  Future<void> searchMyLinks(String text, int pageNum) async {
    try {
      currentText = text;
      page = pageNum;
      emit(LinkListLoadingState());

      if (pageNum == 0) {
        // 새 검색 시 전체 결과 가져오기
        _allSearchResults = await _linkRepository.searchLinks(text);
        totalLinks.clear();
      }

      // 페이지네이션
      final start = pageNum * _pageSize;
      final end = (start + _pageSize).clamp(0, _allSearchResults.length);
      final pagedLinks = _allSearchResults.sublist(
        start.clamp(0, _allSearchResults.length),
        end,
      );

      final hasMorePages = end < _allSearchResults.length;
      hasMore.emit(hasMorePages ? ScrollableType.can : ScrollableType.cannot);

      final links = pagedLinks.map((l) => l.toLink()).toList();
      totalLinks.addAll(links);
      hasAdded = true;

      emit(LinkListLoadedState(links, _allSearchResults.length));
    } catch (e) {
      Log.e('LocalSearchLinksCubit.searchMyLinks error: $e');
      emit(LinkListErrorState(e.toString()));
    }
  }

  /// 다른 사람 링크 검색 (오프라인에서는 미지원 - 내 링크로 대체)
  Future<void> searchLinks(String text, int pageNum) async {
    // 오프라인 모드에서는 다른 사람의 링크 검색을 지원하지 않음
    // 내 링크 검색으로 대체
    await searchMyLinks(text, pageNum);
  }

  void refresh() {
    totalLinks.clear();
    _allSearchResults.clear();
    searchMyLinks(currentText, 0);
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      hasAdded = true;
      searchMyLinks(currentText, page + 1);
    }
  }

  void loadedNewLinks() {
    hasAdded = false;
  }

  void clear() {
    totalLinks.clear();
    _allSearchResults.clear();
    currentText = '';
  }
}
