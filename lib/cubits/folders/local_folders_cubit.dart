import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_model_extensions.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB를 사용하는 폴더 Cubit
/// GetFoldersCubit을 대체
class LocalFoldersCubit extends Cubit<FoldersState> {
  LocalFoldersCubit({bool? excludeUnclassified}) : super(FolderInitialState()) {
    if (excludeUnclassified ?? false) {
      getFoldersWithoutUnclassified();
    } else {
      getFolders(isFirst: true);
    }
  }

  List<Folder> folders = [];

  final LocalFolderRepository _folderRepository = getIt();

  Future<void> getFolders({bool? isFirst}) async {
    try {
      emit(FolderLoadingState());

      final localFolders = await _folderRepository.getAllFolders();
      folders = localFolders.toFolderList();

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
    return folders.fold<int>(
      0,
      (previousValue, element) => previousValue + (element.links ?? 0),
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

  /// visible (isClassified) 토글
  Future<bool> transferVisible(Folder folder) async {
    try {
      if (folder.id == null) return false;

      final localFolder = await _folderRepository.getFolderById(folder.id!);
      if (localFolder == null) return false;

      final updated = localFolder.copyWith(
        isClassified: !localFolder.isClassified,
      );
      await _folderRepository.updateFolder(updated);
      await getFolders();
      return true;
    } catch (e) {
      Log.e('LocalFoldersCubit.transferVisible error: $e');
      return false;
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

  /// 폴더 이름 및 visible 변경
  Future<bool> changeNameAndVisible(Folder folder) async {
    try {
      if (folder.id == null) return false;

      final localFolder = await _folderRepository.getFolderById(folder.id!);
      if (localFolder == null) return false;

      final updated = localFolder.copyWith(
        name: folder.name,
        isClassified: folder.visible,
      );
      await _folderRepository.updateFolder(updated);
      await getFolders();
      return true;
    } catch (e) {
      Log.e('LocalFoldersCubit.changeNameAndVisible error: $e');
      return false;
    }
  }

  /// 폴더 삭제
  Future<bool> delete(Folder folder) async {
    try {
      if (folder.id == null) return false;

      await _folderRepository.deleteFolder(folder.id!);
      await getFolders();
      return true;
    } catch (e) {
      Log.e('LocalFoldersCubit.delete error: $e');
      return false;
    }
  }

  /// 폴더 생성
  Future<int?> createFolder(String name) async {
    try {
      final now = DateTime.now().toIso8601String();
      final newFolder = LocalFolder(
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _folderRepository.createFolder(newFolder);
      await getFolders();
      return id;
    } catch (e) {
      Log.e('LocalFoldersCubit.createFolder error: $e');
      return null;
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
