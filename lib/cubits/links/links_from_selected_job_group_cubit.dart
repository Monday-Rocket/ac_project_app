import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/page_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedJobGroupCubit extends Cubit<List<Link>> {
  LinksFromSelectedJobGroupCubit(): super([]) {
    getSelectedJobLinks(1, 0);
  }

  final linkApi = LinkApi();

  HasMoreCubit hasMore = HasMoreCubit();
  int selectedJobId = 1;
  int page = 0;

  Future<void> getSelectedJobLinks(int jobGroupId, int pageNum) async {
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

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      getSelectedJobLinks(selectedJobId, page + 1);
    }
  }

  List<Link> _setScrollState(SearchedLinks data) {
    page = data.pageNum ?? 0;
    final hasPage = hasMorePage(data);
    Log.i('hasPage: $hasPage');
    hasMore.emit(hasPage ? ScrollableType.can : ScrollableType.cannot);

    return data.contents ?? [];
  }
}
