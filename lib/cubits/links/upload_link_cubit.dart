import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/upload_type.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:ac_project_app/util/url_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UploadLinkCubit extends Cubit<UploadResult> {
  UploadLinkCubit()
      : super(UploadResult(state: UploadResultState.none));

  final LinkApi linkApi = getIt();

  // ignore: avoid_positional_boolean_parameters
  Future<UploadResult> completeRegister(
    String url,
    String describe,
    int? folderId,
    UploadType uploadType,
  ) async {
    try {
      final metadata = await UrlLoader.loadData(url);
      final rawTitle = metadata.title ?? '';

      final result = UploadResult(
        state: await linkApi.postLink(
          Link(
            url: url,
            image: metadata.image,
            title: getShortTitle(rawTitle),
            describe: describe,
            folderId: folderId,
            time: getCurrentTime(),
            inflowType: uploadType.name,
          ),
        ),
        metadata: metadata,
      );
      emit(result);
      return result;
    } catch (e) {
      Log.e(e);
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
      Log.e(e);
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
}
