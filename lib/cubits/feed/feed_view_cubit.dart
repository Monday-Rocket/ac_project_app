import 'package:ac_project_app/cubits/links/feed_data_state.dart';
import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/models/feed/feed_data.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedViewCubit extends Cubit<FeedDataState> {
  FeedViewCubit(List<Folder> folders) : super(FeedDataInitialState()) {
    emit(FeedDataLoadingState());
    globalFolders.addAll(folders);
    if (folders.isNotEmpty) {
      getLinks(0, page);
    }
  }

  final linkApi = LinkApi();
  final hasMore = HasMoreCubit();
  final globalFolders = <Folder>[];

  int currentIndex = 0;
  int page = 0;

  Future<void> getLinks(int index, int pageNum) async {
    currentIndex = index;

    final folder = globalFolders[index];
    final result = await linkApi.getLinksFromSelectedFolder(folder, pageNum);
    result.when(
      success: (data) {
        emit(
          FeedDataLoadedState(
            FeedData(folders: globalFolders, links: data.contents ?? []),
          ),
        );
      },
      error: (msg) {
        emit(FeedDataErrorState(msg));
      },
    );
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      emit(FeedDataLoadingState());
      getLinks(currentIndex, page + 1);
    }
  }

  void selectFolder(int index) {
    emit(FeedDataLoadingState());
    getLinks(index, 0);
  }
}
