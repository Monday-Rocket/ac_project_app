import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlDataCubit extends Cubit<List<Metadata>> {
  UrlDataCubit(super.initialState);

  Future<void> loadUrls() async {
    final urlList = await ShareDataProvider.getShareDataList();
    final metadataList = <Metadata>[];
    for (final url in urlList) {
      try {
        final response = await http.get(Uri.parse(url));
        final document = MetadataFetch.responseToDocument(response);
        final data = MetadataParser.openGraph(document);
        Log.i(data.toJson());
        metadataList.add(data);
      } on Exception catch (e) {
        Log.e(e.toString());
      }
    }
    emit(metadataList);
  }
}
