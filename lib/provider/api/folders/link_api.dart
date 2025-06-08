import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class LinkApi {
  LinkApi(this._client);

  final CustomClient _client;

  Future<Result<SearchedLinks>> getLinksFromSelectedFolder(
    Folder folder,
    int pageNum,
  ) async {
    final result = await _client.getUri(
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

  Future<UploadResultState> postLink(Link link) async {
    final result = await _client.postUri(
      '/links',
      body: {
        'url': link.url,
        'title': link.title,
        'image': link.image,
        'describe': link.describe,
        'created_at': link.time,
        'folder_id': link.folderId,
        'inflow_type': link.inflowType,
      },
    );
    return result.when(
      success: (data) {
        return UploadResultState.success;
      },
      error: (msg) {
        if (msg == '3000' || msg == '2001') {
          return UploadResultState.duplicated;
        }
        return UploadResultState.apiError;
      },
    );
  }

  Future<bool> patchLink(Link link) async {
    final result = await _client.patchUri(
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

  Future<Result<SearchedLinks>> getLinks(
    int pageNum,
  ) async {
    final result = await _client.getUri('/job-groups/0/links?'
        'page_no=$pageNum&'
        'page_size=10');

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
    final result = await _client.getUri('/links/unclassified?'
        'page_no=$pageNum&'
        'page_size=10');
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
    final result = await _client.deleteUri('/links/${link.id}');
    return result.when(
      success: (data) {
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }

  Future<Result<SearchedLinks>> searchOtherLinks(
    String text,
    int pageNum,
  ) async {
    final result = await _client.getUri(
      '/links/search?'
      'my_links_only=false&'
      'keyword=$text&'
      'page_no=$pageNum&'
      'page_size=10',
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

  Future<Result<SearchedLinks>> searchMyLinks(String text, int pageNum) async {
    final result = await _client.getUri(
      '/links/search?'
      'my_links_only=true&'
      'keyword=$text&'
      'page_no=$pageNum&'
      'page_size=10',
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

  Future<bool> changeFolder(Link link, int folderId) async {
    final result = await _client.patchUri(
      '/links/${link.id}',
      body: {
        'folder_id': folderId,
      },
    );
    return result.when(
      success: (_) {
        return true;
      },
      error: (_) {
        return false;
      },
    );
  }

  Future<Result<Link>> getLinkFromId(String linkId) async {
    final result = await _client.getUri('/links/$linkId');

    return result.when(
      success: (data) => Result.success(
        Link.fromJson(data as Map<String, dynamic>),
      ),
      error: Result.error,
    );
  }

  Future<Result<SearchedLinks>> searchLinksFromFolder(
    String text,
    int folderId,
    int pageNum,
  ) async {
    final result = await _client.getUri(
      '/links/search/folder/$folderId?'
      'keyword=$text&'
      'page_no=$pageNum&'
      'page_size=10',
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
}
