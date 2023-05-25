import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/upload_type.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UploadLinkCubit extends Cubit<UploadResultState> {
  UploadLinkCubit() : super(UploadResultState.success);

  final LinkApi linkApi = getIt();

  // ignore: avoid_positional_boolean_parameters
  Future<UploadResultState> completeRegister(
    String url,
    String describe,
    int? folderId,
    UploadType uploadType,
  ) async {
    try {
      final metadata = await UrlLoader.loadData(url);
      final rawTitle = metadata.title ?? '';
      final result = await linkApi.postLink(
        Link(
          url: url,
          image: metadata.image,
          title: getShortTitle(rawTitle),
          describe: describe,
          folderId: folderId,
          time: getCurrentTime(),
          inflowType: uploadType.name,
        ),
      );

      emit(result);
      return result;
    } catch (e) {
      emit(UploadResultState.error);
      return UploadResultState.error;
    }
  }
}
