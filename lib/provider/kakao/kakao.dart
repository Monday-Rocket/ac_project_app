import 'dart:async';

import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart' as my_link;
import 'package:ac_project_app/models/profile/profile.dart' as app_profile;
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/url_valid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

class Kakao {
  static Future<void> sendKakaoLinkShare(my_link.Link link) async {
    final defaultFeed = FeedTemplate(
      content: Content(
        title: link.title ?? '',
        imageUrl: Uri.parse(link.image ?? ''),
        link: Link(
          androidExecutionParams: {'linkId': '${link.id}'},
          iosExecutionParams: {'linkId': '${link.id}'},
        ),
        description: link.describe ?? '',
      ),
      buttons: [
        Button(
          title: '앱으로 보기',
          link: Link(
            androidExecutionParams: {'linkId': '${link.id}'},
            iosExecutionParams: {'linkId': '${link.id}'},
          ),
        ),
      ],
    );

    // 카카오톡 실행 가능 여부 확인
    final isKakaoTalkSharingAvailable =
        await ShareClient.instance.isKakaoTalkSharingAvailable();

    if (isKakaoTalkSharingAvailable) {
      try {
        final uri =
            await ShareClient.instance.shareDefault(template: defaultFeed);
        await ShareClient.instance.launchKakaoTalk(uri);
        Log.d('카카오톡 공유 완료');
      } catch (error) {
        Log.d('카카오톡 공유 실패 $error');
      }
    } else {
      try {
        final shareUrl = await WebSharerClient.instance
            .makeDefaultUrl(template: defaultFeed);
        await launchBrowserTab(shareUrl, popupOpen: true);
      } catch (error) {
        Log.d('카카오톡 공유 실패 $error');
      }
    }
  }

  static Future<void> sendFolderKakaoShare(
      Folder folder, app_profile.Profile profile) async {
    final profileImageUrl =
        await ProfileImage(profile.profileImage).makeImageUrl();

    // isValidUrl(url)
    final isValid = await isValidUrl(folder.thumbnail ?? '');
    final imageUrl = isValid
        ? getValidFolderImageUrl(folder)
        : await getNotValidFolderImageUrl(folder);

    final params = {'folderId': '${folder.id}', 'userId': '${profile.id}'};
    final defaultFeed = FeedTemplate(
      content: Content(
        title: '링크풀에서 폴더를 공유받았어요!',
        imageUrl: Uri.parse(imageUrl),
        link: Link(
          androidExecutionParams: params,
          iosExecutionParams: params,
        ),
        description: '공유받은 폴더 속 링크를 확인해 볼까요?',
      ),
      itemContent: ItemContent(
        profileText: profile.nickname,
        profileImageUrl: Uri.parse(profileImageUrl),
      ),
      buttons: [
        Button(
          title: '앱으로 보기',
          link: Link(
            androidExecutionParams: params,
            iosExecutionParams: params,
          ),
        ),
      ],
    );

    // 카카오톡 실행 가능 여부 확인
    final isKakaoTalkSharingAvailable =
        await ShareClient.instance.isKakaoTalkSharingAvailable();

    if (isKakaoTalkSharingAvailable) {
      try {
        final uri =
            await ShareClient.instance.shareDefault(template: defaultFeed);
        await ShareClient.instance.launchKakaoTalk(uri);
        Log.d('카카오톡 공유 완료');
      } catch (error) {
        Log.d('카카오톡 공유 실패 $error');
      }
    } else {
      try {
        final shareUrl = await WebSharerClient.instance
            .makeDefaultUrl(template: defaultFeed);
        await launchBrowserTab(shareUrl, popupOpen: true);
      } catch (error) {
        Log.d('카카오톡 공유 실패 $error');
      }
    }
  }

  static String getValidFolderImageUrl(Folder folder) {
    return folder.thumbnail ?? '';
  }

  static Future<String> getNotValidFolderImageUrl(Folder folder) async {
    final imageUrl = await FirebaseStorage.instance
        .refFromURL('gs://ac-project-d04ee.appspot.com/empty_folder.png')
        .getDownloadURL();
    return imageUrl;
  }

  static void receiveLink(BuildContext context, {String? url}) {
    if (url != null) {
      _receiveLink(url, context);
    } else {
      receiveKakaoScheme().then((_) {
        kakaoSchemeStream.listen((url) {
          if (url != null) {
            _receiveLink(url, context);
          }
        });
      });
    }
  }

  static void _receiveLink(String url, BuildContext context) {
    final query = Uri.parse(url).queryParameters;

    if (query.keys.contains('linkId')) {
      // 오프라인 모드: 로컬 DB에서 링크 조회
      final linkIdStr = query['linkId']!;
      final linkId = int.tryParse(linkIdStr);
      if (linkId == null) {
        showBottomToast(context: context, '링크 정보를 확인할 수 없습니다.');
        return;
      }

      getIt<LocalLinkRepository>().getLinkById(linkId).then((link) {
        if (link != null) {
          Navigator.pushNamed(
            context,
            Routes.linkDetail,
            arguments: {
              'link': link,
              'isMine': true,
            },
          );
        } else {
          showBottomToast(context: context, '링크 정보를 확인할 수 없습니다.');
        }
      });
    }
  }
}
