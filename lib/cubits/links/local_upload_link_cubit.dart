import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/upload_type.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:ac_project_app/util/url_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB에 링크를 저장하는 Cubit
/// UploadLinkCubit을 대체
class LocalUploadLinkCubit extends Cubit<UploadResult> {
  LocalUploadLinkCubit() : super(UploadResult(state: UploadResultState.none));

  final LocalLinkRepository _linkRepository = getIt();
  final LocalFolderRepository _folderRepository = getIt();

  Future<UploadResult> completeRegister(
    String url,
    String describe,
    int? folderId,
    UploadType uploadType,
  ) async {
    try {
      final metadata = await UrlLoader.loadData(url);
      final rawTitle = metadata.title ?? '';

      // folderId가 null이면 미분류 폴더 사용
      int targetFolderId;
      if (folderId != null) {
        targetFolderId = folderId;
      } else {
        final unclassified = await _folderRepository.getUnclassifiedFolder();
        targetFolderId = unclassified?.id ?? 1;
      }

      final now = DateTime.now().toIso8601String();
      final localLink = LocalLink(
        folderId: targetFolderId,
        url: url,
        title: getShortTitle(rawTitle),
        image: metadata.image,
        describe: describe,
        inflowType: uploadType.name,
        createdAt: now,
        updatedAt: now,
      );

      await _linkRepository.createLink(localLink);

      final result = UploadResult(
        state: UploadResultState.success,
        metadata: metadata,
      );
      emit(result);
      return result;
    } catch (e) {
      Log.e('LocalUploadLinkCubit.completeRegister error: $e');
      final errorResult = UploadResult(state: UploadResultState.error);
      emit(errorResult);
      return errorResult;
    }
  }

  bool isValidateUrl(String url) {
    return UrlLoader.isValidateUrl(url);
  }

  Future<void> getMetadata(String validUrl) async {
    try {
      emit(UploadResult(state: UploadResultState.isValid, metadata: await UrlLoader.loadData(validUrl)));
    } catch (e) {
      Log.e('LocalUploadLinkCubit.getMetadata error: $e');
      emit(UploadResult(state: UploadResultState.error));
    }
  }

  void validateMetadata(String url) {
    if (isValidateUrl(url)) {
      getMetadata(url);
    } else {
      emit(UploadResult(state: UploadResultState.none));
    }
  }

  /// URL 중복 체크
  Future<bool> isUrlDuplicate(String url) async {
    return _linkRepository.isUrlExists(url);
  }
}
