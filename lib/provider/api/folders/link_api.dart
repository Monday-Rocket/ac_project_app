import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class LinkApi {
  final client = CustomClient();

  Future<Result<SearchedLinks>> getLinksFromSelectedFolder(
    Folder folder,
    int pageNum,
  ) async {
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

  Future<UploadResultState> postLink(Link link) async {
    final result = await client.postUri(
      '/links',
      body: {
        'url': link.url,
        'title': link.title,
        'image': link.image,
        'describe': link.describe,
        'created_at': link.time,
        'folder_id': link.folderId,
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

  Future<Result<SearchedLinks>> getJobGroupLinks(
    int jobGroup,
    int pageNum,
  ) async {
    final result = await client.getUri('/job-groups/$jobGroup/links?'
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
    final result = await client.getUri('/links/unclassified?'
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

  Future<Result<SearchedLinks>> searchOtherLinks(
    String text,
    int pageNum,
  ) async {
    final result = await client.getUri(
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
    final result = await client.getUri(
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
    final result = await client.patchUri(
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
}
