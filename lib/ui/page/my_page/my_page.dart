// ignore_for_file: avoid_positional_boolean_parameters, non_constant_identifier_names

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/logout.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<GetProfileInfoCubit>().loadProfileData();
    return Column(
      children: [
        BlocBuilder<GetProfileInfoCubit, ProfileState>(
          builder: (profileContext, state) {
            if (state is ProfileLoadedState) {
              final profile = state.profile;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.profile)
                          .then((result) {
                        if (result == true) {
                          Navigator.pushReplacementNamed(
                            context,
                            Routes.home,
                            arguments: {'index': 3},
                          );
                          showBottomToast('프로필 이미지를 변경했어요!');
                        }
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 90, bottom: 6),
                      width: 105,
                      height: 105,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Image.asset(
                            profile.profileImage,
                            errorBuilder: (_, __, ___) {
                              return Image.asset(
                                'assets/images/profile/img_01_on.png',
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: SvgPicture.asset(
                              'assets/images/ic_change.svg',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    profile.nickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xff0e0e0e),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else {
              return const SizedBox(
                height: 144,
              );
            }
          },
        ),
        const SizedBox(
          height: 47,
        ),
        MenuList(context),
      ],
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
            case '로그아웃':
              {
                showMyPageDialog(
                  title: '로그아웃',
                  content: '계정을 로그아웃 하시겠어요?',
                  parentContext: context,
                  leftText: '취소',
                  rightText: '로그아웃',
                  leftCallback: () => Navigator.pop(context),
                  rightCallback: () => logout(context),
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
                    UserApi().deleteUser().then((value) {
                      if (value) {
                        Navigator.of(context).pop(true);
                        Navigator.pushReplacementNamed(context, Routes.login);
                      } else {
                        Navigator.of(context).pop(true);
                        showBottomToast('회원탈퇴 실패');
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
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 24,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                menuName,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              if (arrow) const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        DivisionLine(),
        MenuItem('이용 약관'),
        DivisionLine(size: 1),
        MenuItem('개인정보 처리방침'),
        DivisionLine(size: 1),
        MenuItem('도움말'),
        DivisionLine(),
        MenuItem('로그아웃', arrow: false),
        DivisionLine(size: 1),
        MenuItem('회원탈퇴', arrow: false, color: redError),
        DivisionLine(size: 1),
      ],
    );
  }
}
