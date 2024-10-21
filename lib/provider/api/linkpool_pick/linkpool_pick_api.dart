import 'package:ac_project_app/models/linkpool_pick/linkpool_pick.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class LinkpoolPickApi {
  LinkpoolPickApi(this._client);

  final CustomClient _client;

  Future<Result<List<LinkpoolPick>>> getLinkpoolPicks() async {
    final result = await _client.getUri('/picks');

    return result.when(
      success: (data) {
        return Result.success(LinkpoolPick.fromJsonList(data as List<dynamic>));
      },
      error: (msg) {
        return Result.error(msg);
      },
    );
  }
}
