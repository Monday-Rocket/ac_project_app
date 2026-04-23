import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_model_extensions.dart';
import 'package:ac_project_app/provider/local/folder_exceptions.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/recent_folders_repository.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB를 사용하는 폴더 Cubit
/// GetFoldersCubit을 대체
class LocalFoldersCubit extends Cubit<FoldersState> {
  LocalFoldersCubit({bool? excludeUnclassified, bool rootsOnly = false})
      : _rootsOnly = rootsOnly,
        super(FolderInitialState()) {
    if (excludeUnclassified ?? false) {
      getFoldersWithoutUnclassified();
    } else {
      getFolders(isFirst: true);
    }
  }

  /// true면 최상위 폴더만 조회 (중첩 폴더 UI의 홈 리스트 용도).
  final bool _rootsOnly;

  List<Folder> folders = [];

  final LocalFolderRepository _folderRepository = getIt();

  Future<void> getFolders({bool? isFirst}) async {
    try {
      emit(FolderLoadingState());

      final localFolders = _rootsOnly
          ? await _folderRepository.getRootFolders()
          : await _folderRepository.getAllFolders();
      final recursiveCounts = _rootsOnly
          ? await _folderRepository.getRecursiveLinkCounts()
          : const <int, int>{};
      folders = _rootsOnly
          ? localFolders.toFolderListWithRecursiveCounts(recursiveCounts)
          : localFolders.toFolderList();

      final totalLinksText = '${getTotalLinksCount()}';
      final addedLinksCount = await getAddedLinksCount();
      if (isFirst ?? false) {
        await SharedPrefHelper.saveKeyValue('savedLinksCount', getTotalLinksCount());
      }

      emit(FolderLoadedState(folders, totalLinksText, addedLinksCount));
    } catch (e) {
      Log.e('LocalFoldersCubit.getFolders error: $e');
      emit(FolderErrorState(e.toString()));
    }
  }

  int getTotalLinksCount() {
    // rootsOnly일 때는 루트의 linksTotal(재귀 카운트)을 써야 전체 합이 정확.
    return folders.fold<int>(
      0,
      (previousValue, element) =>
          previousValue + (_rootsOnly ? (element.linksTotal ?? 0) : (element.links ?? 0)),
    );
  }

  Future<void> getFoldersWithoutUnclassified() async {
    try {
      emit(FolderLoadingState());

      final localFolders = await _folderRepository.getClassifiedFolders();
      folders = localFolders.toFolderList();

      final totalLinksText = '${getTotalLinksCount()}';
      final addedLinksCount = await getAddedLinksCount();
      emit(FolderLoadedState(folders, totalLinksText, addedLinksCount));
    } catch (e) {
      Log.e('LocalFoldersCubit.getFoldersWithoutUnclassified error: $e');
      emit(FolderErrorState(e.toString()));
    }
  }

  /// 폴더 이름 변경
  Future<bool> changeName(Folder folder, String name) async {
    try {
      if (folder.id == null) return false;

      final localFolder = await _folderRepository.getFolderById(folder.id!);
      if (localFolder == null) return false;

      final updated = localFolder.copyWith(name: name);
      await _folderRepository.updateFolder(updated);
      await getFolders();
      return true;
    } catch (e) {
      Log.e('LocalFoldersCubit.changeName error: $e');
      return false;
    }
  }

  /// 폴더 삭제
  Future<bool> delete(Folder folder) async {
    try {
      if (folder.id == null) return false;

      await _folderRepository.deleteFolder(folder.id!);
      // 최근 사용 목록에서도 정리 (삭제된 폴더 ID 잔존 방지)
      await const RecentFoldersRepository().remove(folder.id!);
      await getFolders();
      return true;
    } catch (e) {
      Log.e('LocalFoldersCubit.delete error: $e');
      return false;
    }
  }

  /// 폴더 생성. 결과는 CreateFolderResult로 구분 전달.
  /// - 성공: Created(id)
  /// - 형제 이름 중복: DuplicateSibling
  /// - 부모 폴더 없음 또는 부모가 미분류: ParentMissing
  /// - 기타 실패: CreateFolderFailed(error)
  ///
  /// 검증 로직은 Repository가 단일 출처. Cubit은 도메인 예외를 결과 타입으로 변환만 한다.
  Future<CreateFolderResult> createFolder(String name, {int? parentId}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final newFolder = LocalFolder(
        name: name,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _folderRepository.createFolder(newFolder);
      await getFolders();
      return Created(id);
    } on SiblingNameTakenException {
      return const DuplicateSibling();
    } on ParentNotFoundException {
      return const ParentMissing();
    } on ParentNotClassifiedException {
      return const ParentMissing();
    } catch (e) {
      Log.e('LocalFoldersCubit.createFolder error: $e');
      return CreateFolderFailed(e);
    }
  }

  /// 폴더 필터링
  Future<void> filter(String name) async {
    final totalLinksText = '${getTotalLinksCount()}';
    final addedLinksCount = await getAddedLinksCount();
    if (name.isEmpty) {
      emit(FolderLoadedState(folders, totalLinksText, addedLinksCount));
    } else {
      final filtered = folders.where((folder) => folder.name?.contains(name) ?? false).toList();
      emit(FolderLoadedState(filtered, totalLinksText, addedLinksCount));
    }
  }

  Future<int> getAddedLinksCount() async => getTotalLinksCount() - await SharedPrefHelper.getValueFromKey<int>('savedLinksCount', defaultValue: 0);

  /// 미분류 폴더 ID 가져오기
  Future<int?> getUnclassifiedFolderId() async {
    final unclassified = await _folderRepository.getUnclassifiedFolder();
    return unclassified?.id;
  }
}
