import 'dart:async';

import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/provider/login/firebase_auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_project_app/models/link/link.dart' as MyLink;

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

  static Future<void> sendKakaoShare(MyLink.Link link) async {
    final defaultFeed = FeedTemplate(
      content: Content(
        title: link.title ?? '',
        imageUrl: Uri.parse(link.image ?? ''),
        link: Link(
          webUrl: Uri.parse(link.url ?? ''),
          mobileWebUrl: Uri.parse(link.url ?? ''),

        ),
      ),
      itemContent: ItemContent(
        profileImageUrl: Uri.parse('https://is4-ssl.mzstatic.com/image/thumb/Purple116/v4/93/92/c7/9392c7d0-4e50-1240-9716-0df433767bdd/AppIcon-1x_U007emarketing-0-6-0-85-220.png/460x0w.webp'),
        profileText: link.user?.nickname ?? '',
      ),
      buttonTitle: '링크풀에서 확인하기',
    );

    // 카카오톡 실행 가능 여부 확인
    final isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

    if (isKakaoTalkSharingAvailable) {
      try {
        final uri = await ShareClient.instance.shareDefault(template: defaultFeed);
        await ShareClient.instance.launchKakaoTalk(uri);
        print('카카오톡 공유 완료');
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    } else {
      try {
        final shareUrl = await WebSharerClient.instance.makeDefaultUrl(template: defaultFeed);
        await launchBrowserTab(shareUrl, popupOpen: true);
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    }
  }
}
