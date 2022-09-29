import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlDataCubit extends Cubit<List<Metadata>> {
  UrlDataCubit(super.initialState);

  Future<void> loadUrls() async {
    final urlList = await ShareDataProvider.getShareDataList();

    final metadataList = <Metadata>[];

    for (final url in urlList) {
      final data = await MetadataFetch.extract(url);
      if (data != null) {
        metadataList.add(data);
      }
    }
    emit(metadataList);
  }
}
