// ignore_for_file: avoid_positional_boolean_parameters, non_constant_identifier_names

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/logout.dart';
import 'package:ac_project_app/provider/offline_mode_provider.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _isOfflineModeCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineModeStatus();
  }

  Future<void> _loadOfflineModeStatus() async {
    final isComplete = await OfflineModeProvider.isOfflineModeCompleted();
    if (mounted) {
      setState(() {
        _isOfflineModeCompleted = isComplete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 심플 헤더
          Padding(
            padding: EdgeInsets.only(
              top: 60.w,
              left: 24.w,
              right: 24.w,
              bottom: 24.w,
            ),
            child: Text(
              '설정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28.sp,
                color: grey900,
              ),
            ),
          ),
          MenuList(context),
        ],
      ),
    );
  }

  Widget MenuList(BuildContext context) {
    Widget DivisionLine({double size = 4}) {
      return Container(
        height: size,
        width: MediaQuery.of(context).size.width,
        color: grey200,
      );
    }

    Widget MenuItem(
      String menuName, {
      bool arrow = true,
      Color color = grey900,
    }) {
      return InkWell(
        key: Key('menu:$menuName'),
        onTap: () {
          switch (menuName) {
            case '이용 약관':
              {
                launchUrl(
                  Uri.parse(approveSecondLink),
                  mode: LaunchMode.externalApplication,
                );
                break;
              }
            case '개인정보 처리방침':
              {
                launchUrl(
                  Uri.parse(personalInfoLink),
                  mode: LaunchMode.externalApplication,
                );
                break;
              }
            case '도움말':
              {
                launchUrl(
                  Uri.parse(helpLink),
                  mode: LaunchMode.externalApplication,
                );
                break;
              }
            case '오픈소스 라이센스':
              {
                Navigator.pushNamed(context, Routes.ossLicenses);
                break;
              }
            case '로그아웃':
              {
                showMyPageDialog(
                  title: '로그아웃',
                  content: '계정을 로그아웃 하시겠어요?',
                  parentContext: context,
                  leftText: '취소',
                  rightText: '로그아웃',
                  leftCallback: () => Navigator.pop(context),
                  rightCallback: () => logout(() {
                    SharedPrefHelper.saveKeyValue('savedLinksCount', 0);
                    Navigator.of(context).pop(true);
                    Navigator.pushReplacementNamed(context, Routes.login);
                  }),
                );
                break;
              }
            case '회원탈퇴':
              {
                showMyPageDialog(
                  title: '정말 탈퇴하시겠어요?',
                  content: '지금 탈퇴하면 그동안 모은 링크가 사라져요',
                  parentContext: context,
                  leftText: '회원 탈퇴',
                  rightText: '탈퇴 취소',
                  leftCallback: () {
                    getIt<UserApi>().deleteUser().then((value) {
                      if (value) {
                        SharedPrefHelper.saveKeyValue('savedLinksCount', 0);
                        Navigator.of(context).pop(true);
                        Navigator.pushReplacementNamed(context, Routes.login);
                      } else {
                        Navigator.of(context).pop(true);
                        showBottomToast(context: context, '회원탈퇴 실패');
                      }
                    });
                  },
                  rightCallback: () => Navigator.pop(context),
                  icon: true,
                );
                break;
              }
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 20.w,
            horizontal: 24.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                menuName,
                style: TextStyle(
                  color: color,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              if (arrow) Icon(Icons.arrow_forward_ios_rounded, size: 16.w),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        DivisionLine(),
        MenuItem('이용 약관'),
        DivisionLine(size: 1.w),
        MenuItem('개인정보 처리방침'),
        DivisionLine(size: 1.w),
        MenuItem('도움말'),
        DivisionLine(size: 1.w),
        MenuItem('오픈소스 라이센스'),
        DivisionLine(),
        // 오프라인 모드 완료 시 로그아웃/회원탈퇴 메뉴 숨김
        if (!_isOfflineModeCompleted) ...[
          MenuItem('로그아웃', arrow: false),
          DivisionLine(size: 1.w),
          MenuItem('회원탈퇴', arrow: false, color: redError),
          DivisionLine(size: 1.w),
        ],
      ],
    );
  }
}
