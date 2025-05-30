import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/share/invite_info.dart';
import 'package:ac_project_app/models/share/invite_link.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class ShareFolderApi {
  ShareFolderApi(this._client);

  final CustomClient _client;

  Future<Result<InviteLink>> generateInviteToken(int? folderId) async {
    final result = await _client.postUri('/folders/$folderId/invite-link');
    return result.when(
      success: (inviteLink) {
        return Result.success(
            InviteLink.fromJson(inviteLink as Map<String, dynamic>));
      },
      error: Result.error,
    );
  }

  Future<Result<InviteInfo>> getInviteLinkInfo(String folderId) async {
    final result = await _client.getUri('/folders/$folderId/invite-link');
    return result.when(
      success: (inviteInfo) {
        return Result.success(
            InviteInfo.fromJson(inviteInfo as Map<String, dynamic>));
      },
      error: Result.error,
    );
  }

  Future<Result<void>> acceptInviteLink(
    String folderId,
    String inviteToken,
  ) async {
    final result = await _client.postUri(
      '/folders/$folderId/invite-link/accept',
      body: {'invite_token': inviteToken},
    );
    return result.when(
      success: (_) => const Result.success(null),
      error: Result.error,
    );
  }

  Future<Result<List<DetailUser>>> getFolderMembers(String folderId) async {
    final result = await _client.getUri('/folders/$folderId/members');
    return result.when(
      success: (members) {
        final list = <DetailUser>[];
        for (final data in members as List<dynamic>) {
          list.add(DetailUser.fromJson(data as Map<String, dynamic>));
        }
        return Result.success(list);
      },
      error: Result.error,
    );
  }

  Future<Result<void>> delegateFolderAdmin(
    String folderId,
    String userId,
  ) async {
    final result = await _client.postUri(
      '/folders/$folderId/admin/delegate',
      body: {'memberId': userId},
    );
    return result.when(
      success: (_) => const Result.success(null),
      error: Result.error,
    );
  }

  Future<Result<void>> removeFolderMember(
    String folderId,
    String userId,
  ) async {
    final result = await _client.postUri('/folders/$folderId/$userId/displace');
    return result.when(
      success: (_) => const Result.success(null),
      error: Result.error,
    );
  }
}
