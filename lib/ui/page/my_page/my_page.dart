// ignore_for_file: avoid_positional_boolean_parameters, non_constant_identifier_names

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/logout.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                  GestureDetector(
                    onTap: () => moveToProfileImageView(context),
                    child: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(top: 90.h, bottom: 6.h),
                      width: 105.w,
                      height: 105.h,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Image.asset(
                            ProfileImage.makeImagePath(profile.profileImage),
                            errorBuilder: (_, __, ___) {
                              return Assets.images.profile.img01On.image();
                            },
                          ),
                          Container(
                            padding: EdgeInsets.all(4.r),
                            width: 24.w,
                            height: 24.h,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: SvgPicture.asset(
                              Assets.images.icChange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    profile.nickname,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.sp,
                      color: const Color(0xff0e0e0e),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  SizedBox(
                    height: 195.h,
                  ),
                  Text('', style: TextStyle(fontSize: 28.sp)),
                ],
              );
            }
          },
        ),
        SizedBox(
          height: 47.h,
        ),
        MenuList(context),
      ],
    );
  }

  void moveToProfileImageView(BuildContext context) {
    Navigator.pushNamed(context, Routes.profile).then((detailUser) {
      if (detailUser is DetailUser && detailUser.isNotEmpty()) {
        context.read<GetProfileInfoCubit>().updateFromProfile(detailUser);
        showBottomToast(
          context: context,
          '프로필 이미지를 변경했어요!',
        );
      }
    });
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
            case '로그아웃':
              {
                showMyPageDialog(
                  title: '로그아웃',
                  content: '계정을 로그아웃 하시겠어요?',
                  parentContext: context,
                  leftText: '취소',
                  rightText: '로그아웃',
                  leftCallback: () => Navigator.pop(context),
                  rightCallback: () => logout(context, () {
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
                    UserApi().deleteUser().then((value) {
                      if (value) {
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
            vertical: 20.h,
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
              if (arrow) Icon(Icons.arrow_forward_ios_rounded, size: 16.r),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        DivisionLine(),
        MenuItem('이용 약관'),
        DivisionLine(size: 1.r),
        MenuItem('개인정보 처리방침'),
        DivisionLine(size: 1.r),
        MenuItem('도움말'),
        DivisionLine(),
        MenuItem('로그아웃', arrow: false),
        DivisionLine(size: 1.r),
        MenuItem('회원탈퇴', arrow: false, color: redError),
        DivisionLine(size: 1.r),
      ],
    );
  }
}
