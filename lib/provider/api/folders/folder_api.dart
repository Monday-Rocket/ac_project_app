import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class FolderApi {
  final client = CustomClient();

  Future<Result<Folder>> postFolders(List<String> folderNames) async {
    final body = <Map<String, dynamic>>[];

    for (final name in folderNames) {
      body.add({
        'name': name,
      });
    }

    final result = await client.postUri(
      '/folders',
      body: folderNames,
    );
    return result.when(
      success: (data) => Result.success(
        Folder.fromJson(data as Map<String, dynamic>),
      ),
      error: Result.error,
    );
  }

  Future<Result<Folder>> getMyFolders() async {
    final result = await client.getUri('/folders');
    return result.when(
      success: (data) =>
          Result.success(Folder.fromJson(data as Map<String, dynamic>)),
      error: Result.error,
    );
  }

  Future<Result<Link>> getOthersFolder(int userId, String folderName) async {
    final result = await client.getUri('/folders/$userId/$folderName');
    return result.when(
      success: (data) =>
          Result.success(Link.fromJson(data as Map<String, dynamic>)),
      error: Result.error,
    );
  }

  void add(Folder folder) {}
}
