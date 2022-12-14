import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/page_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchLinksCubit extends Cubit<LinkListState> {
  SearchLinksCubit(): super(LinkListInitialState());

  final linkApi = LinkApi();
  HasMoreCubit hasMore = HasMoreCubit();
  int page = 0;
  String currentText = '';

  Future<void> searchLinks(String text, int pageNum) async {

    emit(LinkListLoadingState());

    final result = await linkApi.searchOtherLinks(text, pageNum);
    result.when(
      success: (data) {
        final links = _setScrollState(data);
        emit(LinkListLoadedState(links));
      },
      error: (msg) {
        emit(LinkListErrorState(msg));
      },
    );
  }

  Future<void> searchMyLinks(String text, int pageNum) async {

    emit(LinkListLoadingState());

    final result = await linkApi.searchMyLinks(text, pageNum);
    result.when(
      success: (data) {
        final links = _setScrollState(data);
        emit(LinkListLoadedState(links));
      },
      error: (msg) {
        emit(LinkListErrorState(msg));
      },
    );
  }

  Future<void> refresh() => searchLinks(currentText, 0);

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      searchLinks(currentText, page + 1);
    }
  }

  List<Link> _setScrollState(SearchedLinks data) {
    page = data.pageNum ?? 0;
    final hasPage = hasMorePage(data);
    hasMore.emit(hasPage ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }

}
