import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedFolderCubit extends Cubit<List<Link>> {
  LinksFromSelectedFolderCubit(Folder folder, int pageNum)
      : super([]) {
    getSelectedLinks(folder, pageNum);
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent &&
          hasMore.state == ScrollableType.can) {
        getSelectedLinks(currentFolder!, page + 1);
      } else {
        // Log.i(hasMore.state);
      }
    });
  }

  final linkApi = LinkApi();
  final scrollController = ScrollController();

  HasMoreCubit hasMore = HasMoreCubit();
  Folder? currentFolder;
  int page = 0;

  Future<void> getSelectedLinks(Folder folder, int pageNum) async {
    currentFolder = folder;

    if (folder.isClassified ?? true) {
      final result = await linkApi.getLinksFromSelectedFolder(folder, pageNum);
      result.when(
        success: (data) {
          emit(_setScrollState(data));
        },
        error: (msg) {

        },
      );
    } else {
      final result = await linkApi.getUnClassifiedLinks(pageNum);
      result.when(
        success: (data) {
          emit(_setScrollState(data));
        },
        error: (msg) {

        },
      );
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
