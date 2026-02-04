import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/models/local/local_model_extensions.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB를 사용하는 폴더별 링크 Cubit
/// LinksFromSelectedFolderCubit을 대체
class LocalLinksFromFolderCubit extends Cubit<LinkListState> {
  LocalLinksFromFolderCubit(Folder folder, int pageNum) : super(LinkListInitialState()) {
    getSelectedLinks(folder, pageNum);
  }

  final LocalLinkRepository _linkRepository = getIt();
  final LocalFolderRepository _folderRepository = getIt();

  HasMoreCubit hasMore = HasMoreCubit();
  Folder? currentFolder;
  int page = 0;
  String searchingText = '';
  List<Link> allLinks = [];

  static const int _pageSize = 20;

  Future<void> getSelectedLinks(Folder folder, int pageNum) async {
    try {
      searchingText = '';
      emit(LinkListLoadingState());

      currentFolder = folder;
      page = pageNum;

      List<LocalLink> localLinks;
      int totalCount;

      if (folder.id == null) {
        emit(LinkListErrorState('폴더 ID가 없습니다'));
        return;
      }

      if (folder.isClassified ?? true) {
        localLinks = await _linkRepository.getLinksByFolderId(
          folder.id!,
          limit: _pageSize,
          offset: pageNum * _pageSize,
        );
        totalCount = await _linkRepository.getLinkCountByFolderId(folder.id!);
      } else {
        // 미분류 폴더
        final unclassified = await _folderRepository.getUnclassifiedFolder();
        if (unclassified?.id == null) {
          emit(LinkListErrorState('미분류 폴더를 찾을 수 없습니다'));
          return;
        }
        localLinks = await _linkRepository.getLinksByFolderId(
          unclassified!.id!,
          limit: _pageSize,
          offset: pageNum * _pageSize,
        );
        totalCount = await _linkRepository.getLinkCountByFolderId(unclassified.id!);
      }

      final links = localLinks.toLinkList();

      // 페이지네이션 상태 설정
      final hasMorePages = (pageNum + 1) * _pageSize < totalCount;
      hasMore.emit(hasMorePages ? ScrollableType.can : ScrollableType.cannot);

      if (pageNum == 0) {
        allLinks = links;
      } else {
        allLinks.addAll(links);
      }

      emit(LinkListLoadedState(links, totalCount));
    } catch (e) {
      Log.e('LocalLinksFromFolderCubit.getSelectedLinks error: $e');
      emit(LinkListErrorState(e.toString()));
    }
  }

  Future<void> refresh() async {
    if (currentFolder == null) return;
    allLinks.clear();
    emit(LinkListLoadingState());
    await getSelectedLinks(currentFolder!, 0);
  }

  void loadMore() {
    if (hasMore.state == ScrollableType.can) {
      if (searchingText.isNotEmpty) {
        searchLinksFromSelectedFolder(searchingText, page + 1);
      } else {
        getSelectedLinks(currentFolder!, page + 1);
      }
    }
  }

  void loading() {
    emit(LinkListLoadingState());
  }

  Future<void> searchLinksFromSelectedFolder(
    String text,
    int pageNum,
  ) async {
    try {
      searchingText = text;
      page = pageNum;
      emit(LinkListLoadingState());

      if (currentFolder?.id == null) {
        emit(LinkListErrorState('폴더 ID가 없습니다'));
        return;
      }

      // 폴더 내에서 검색 (로컬에서는 전체 검색 후 필터링)
      final allSearchResults = await _linkRepository.searchLinks(text);
      final folderLinks = allSearchResults
          .where((link) => link.folderId == currentFolder!.id)
          .toList();

      // 페이지네이션
      final start = pageNum * _pageSize;
      final end = (start + _pageSize).clamp(0, folderLinks.length);
      final pagedLinks = folderLinks.sublist(
        start.clamp(0, folderLinks.length),
        end,
      );

      final hasMorePages = end < folderLinks.length;
      hasMore.emit(hasMorePages ? ScrollableType.can : ScrollableType.cannot);

      final links = pagedLinks.map((l) => l.toLink()).toList();
      emit(LinkListLoadedState(links, folderLinks.length));
    } catch (e) {
      Log.e('LocalLinksFromFolderCubit.searchLinksFromSelectedFolder error: $e');
      emit(LinkListErrorState(e.toString()));
    }
  }

  /// 링크 삭제
  Future<bool> deleteLink(int linkId) async {
    try {
      await _linkRepository.deleteLink(linkId);
      await refresh();
      return true;
    } catch (e) {
      Log.e('LocalLinksFromFolderCubit.deleteLink error: $e');
      return false;
    }
  }

  /// 링크 폴더 이동
  Future<bool> moveLink(int linkId, int newFolderId) async {
    try {
      await _linkRepository.moveLink(linkId, newFolderId);
      await refresh();
      return true;
    } catch (e) {
      Log.e('LocalLinksFromFolderCubit.moveLink error: $e');
      return false;
    }
  }

  /// 여러 링크 폴더 이동
  Future<bool> moveLinks(List<int> linkIds, int newFolderId) async {
    try {
      await _linkRepository.moveLinks(linkIds, newFolderId);
      await refresh();
      return true;
    } catch (e) {
      Log.e('LocalLinksFromFolderCubit.moveLinks error: $e');
      return false;
    }
  }
}
