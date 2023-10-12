import 'dart:async';

import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart' as my_link;
import 'package:ac_project_app/models/profile/profile.dart' as Profile;
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart' as my_user_api;
import 'package:ac_project_app/provider/login/firebase_auth_remote_data_source.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/url_valid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Kakao {
  static Future<bool> login() async {
    final isLogin = await _login();

    if (isLogin) {
      final prefs = await SharedPreferences.getInstance();
      unawaited(prefs.setString('loginType', LoginType.kakao.name));
      final user = await UserApi.instance.me();
      // https://velog.io/@ember/Firebase-deploy-Forbidden-%ED%95%B4%EA%B2%B0
      final customToken =
          await FirebaseAuthRemoteDataSource().createCustomToken({
        'uid': user.id.toString(),
        'serviceName': 'kakao',
      });
      final userCredential =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
      return userCredential.user != null;
    }
    return false;
  }

  static Future<bool> _login() async {
    // 카카오 로그인 구현 예제

    // 카카오톡 실행 가능 여부 확인
    // 카카오톡 실행이 가능하면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공');
        return true;
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return false;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
          return true;
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
          return false;
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공');
        return true;
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
        return false;
      }
    }
  }

  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();
      print('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }

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
        print('카카오톡 공유 완료');
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    } else {
      try {
        final shareUrl = await WebSharerClient.instance
            .makeDefaultUrl(template: defaultFeed);
        await launchBrowserTab(shareUrl, popupOpen: true);
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    }
  }

  static Future<void> sendFolderKakaoShare(
      Folder folder, Profile.Profile profile) async {
    final profileImageUrl =
        await ProfileImage(profile.profileImage).makeImageUrl();

    // isValidUrl(url)
    final isValid = await isValidUrl(folder.thumbnail ?? '');
    final imageUrl = await getFolderImageUrl(isValid, folder);

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
        print('카카오톡 공유 완료');
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    } else {
      try {
        final shareUrl = await WebSharerClient.instance
            .makeDefaultUrl(template: defaultFeed);
        await launchBrowserTab(shareUrl, popupOpen: true);
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    }
  }

  static Future<String> getFolderImageUrl(bool isValid, Folder folder) async {
    final imageUrl = isValid ? folder.thumbnail : await FirebaseStorage.instance
        .refFromURL('gs://ac-project-d04ee.appspot.com/empty_folder.png')
        .getDownloadURL();
    return imageUrl ?? '';
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
      getIt<LinkApi>().getLinkFromId(query['linkId']!).then((result) {
        result.when(
          success: (link) {
            Navigator.pushNamed(
              context,
              Routes.linkDetail,
              arguments: {
                'link': link,
              },
            );
          },
          error: (msg) {
            var errorMessage = msg;
            if (msg.isEmpty || msg == '404') {
              errorMessage = '링크 정보를 확인할 수 없습니다.';
            }
            showBottomToast(context: context, errorMessage);
          },
        );
      });
    } else {
      if (query.keys.contains('folderId')) {
        final folderId = query['folderId']!;
        final userId = query['userId'] ?? '';
        getIt<my_user_api.UserApi>().getUsersId(userId).then((result) {
          result.when(
            success: (user) {
              final profileInfoCubit = getIt<GetProfileInfoCubit>();
              final userFoldersCubit = getIt<GetUserFoldersCubit>();
              final isMine =
                  (profileInfoCubit.state as ProfileLoadedState).profile.id ==
                      user.id;

              userFoldersCubit.getFolders(user.id!).then((_) {
                Navigator.of(context).pushNamed(
                  Routes.userFeed,
                  arguments: {
                    'user': user,
                    'folders': userFoldersCubit.state.folderList,
                    'folderId': folderId,
                    'isMine': isMine,
                  },
                );
              });
            },
            error: (e) {
              Log.e(e);
            },
          );
        });
      }
    }
  }
}
