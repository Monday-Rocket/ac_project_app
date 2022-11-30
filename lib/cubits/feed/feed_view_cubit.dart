import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedViewCubit extends Cubit<LinkListState> {
  FeedViewCubit(List<Folder> folders) : super(LinkListInitialState()) {
    emit(LinkListLoadingState());
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
        emit(LinkListLoadedState(data.contents ?? []));
      },
      error: (msg) {
        emit(LinkListErrorState(msg));
      },
    );
  }

  Future<void> refresh() async {
    emit(LinkListLoadingState());
    final folder = globalFolders[currentIndex];
    final result = await linkApi.getLinksFromSelectedFolder(folder, 0);
    result.when(
      success: (data) {
        emit(LinkListLoadedState(data.contents ?? []));
      },
      error: (msg) {
        emit(LinkListErrorState(msg));
      },
    );
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      emit(LinkListLoadingState());
      getLinks(currentIndex, page + 1);
    }
  }

  void selectFolder(int index) {
    emit(LinkListLoadingState());
    getLinks(index, 0);
  }
}
