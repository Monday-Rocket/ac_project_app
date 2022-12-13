import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UploadLinkCubit extends Cubit<UploadResultState> {
  UploadLinkCubit(): super(UploadResultState.success);

  Future<UploadResultState> completeRegister(String url, String describe, int? folderId) async {
    try {
      final metadata = await UrlLoader.loadData(url);
      final result = await LinkApi().postLink(
        Link(
          url: url,
          image: metadata.image,
          title: metadata.title,
          describe: describe,
          folderId: folderId,
          time: getCurrentTime(),
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