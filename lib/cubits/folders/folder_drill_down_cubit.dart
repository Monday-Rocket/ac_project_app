import 'package:ac_project_app/cubits/folders/folder_drill_down_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/local/local_model_extensions.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 특정 폴더를 기준으로 한 드릴다운 상태.
/// 브레드크럼, 직계 하위 폴더(재귀 카운트 포함), 직접 링크를 한꺼번에 로드.
class FolderDrillDownCubit extends Cubit<FolderDrillDownState> {
  FolderDrillDownCubit({
    required this.folderId,
    LocalFolderRepository? folderRepo,
    LocalLinkRepository? linkRepo,
    bool autoLoad = true,
  })  : _folderRepo = folderRepo ?? getIt<LocalFolderRepository>(),
        _linkRepo = linkRepo ?? getIt<LocalLinkRepository>(),
        super(FolderDrillDownInitial()) {
    if (autoLoad) {
      load();
    }
  }

  final int folderId;
  final LocalFolderRepository _folderRepo;
  final LocalLinkRepository _linkRepo;

  Future<void> load() async {
    emit(FolderDrillDownLoading());
    try {
      final breadcrumbRaw = await _folderRepo.getBreadcrumb(folderId);
      final children = await _folderRepo.getChildFolders(folderId);
      final links = await _linkRepo.getLinksByFolderId(folderId);
      final recursiveCounts = await _folderRepo.getRecursiveLinkCounts();

      emit(
        FolderDrillDownLoaded(
          breadcrumb: breadcrumbRaw.toFolderListWithRecursiveCounts(recursiveCounts),
          childFolders:
              children.toFolderListWithRecursiveCounts(recursiveCounts),
          directLinks: links.map((l) => l.toLink()).toList(),
        ),
      );
    } catch (e) {
      Log.e('FolderDrillDownCubit.load error: $e');
      emit(FolderDrillDownError(e.toString()));
    }
  }

  Future<void> refresh() => load();
}
