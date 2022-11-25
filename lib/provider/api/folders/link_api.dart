import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class LinkApi {
  final client = CustomClient();

  Future<Result<SearchedLinks>> getLinksFromSelectedFolder(
      Folder folder, int pageNum) async {
    final result = await client.getUri(
      '/folders/${folder.id}/links?page_no=$pageNum&page_size=10',
    );
    return result.when(
      success: (data) {
        return Result.success(
          SearchedLinks.fromJson(data as Map<String, dynamic>),
        );
      },
      error: Result.error,
    );
  }

  Future<void> postLink(Link link) async {
    final result = await client.postUri(
      '/links',
      body: {
        'url': link.url,
        'title': link.title,
        'image': link.image,
        'describe': link.describe,
        'created_at': link.time,
        'folder': link.folderId,
      },
    );
    result.when(
      success: (data) {},
      error: (msg) {},
    );
  }

  Future<bool> patchLink(Link link) async {
    final result = await client.patchUri(
      '/links/${link.id}',
      body: link.toJson(),
    );
    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }

  Future<Result<SearchedLinks>> getJobGroupLinks(int pageNum) async {
    final result = await client.getUri('/links?pageNo=$pageNum&pageSize=10');
    return result.when(
      success: (data) {
        return Result.success(
          SearchedLinks.fromJson(data as Map<String, dynamic>),
        );
      },
      error: Result.error,
    );
  }

  Future<Result<SearchedLinks>> getHomeLinks(int pageNum) async {
    final result = await client.getUri('/links?pageNo=$pageNum&pageSize=10');
    return result.when(
      success: (data) {
        return Result.success(
          SearchedLinks.fromJson(data as Map<String, dynamic>),
        );
      },
      error: Result.error,
    );
  }

  Future<Result<SearchedLinks>> getUnClassifiedLinks(int pageNum) async {
    final result =
        await client.getUri('/links/unclassified?pageNo=$pageNum&pageSize=10');
    return result.when(
      success: (data) {
        return Result.success(
          SearchedLinks.fromJson(data as Map<String, dynamic>),
        );
      },
      error: Result.error,
    );
  }

  Future<bool> deleteLink(Link link) async {
    final result = await client.deleteUri('/links/${link.id}');
    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }
}
