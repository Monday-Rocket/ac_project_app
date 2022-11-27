// ignore_for_file: avoid_positional_boolean_parameters, non_constant_identifier_names

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LinkArguments {
  LinkArguments({required this.link});

  final String link;
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
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

  void showPopUp({
    required String title,
    required String content,
    required BuildContext context,
    required Future<void> Function() callback,
    bool icon = false,
    bool isLogout = false,
    bool isLeave = false,
  }) {
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Container(
                width: 285,
                height: icon ? 217 : 183,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: icon ? 14 : 16,
                    ),
                    if (icon)
                      const Icon(
                        Icons.error,
                        color: primary800,
                        size: 27,
                      ),
                    SizedBox(
                      height: icon ? 7 : 0,
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: R_Font.PRETENDARD,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(content, textAlign: TextAlign.center),
                    const SizedBox(
                      height: 32,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        callback.call().then((value) {
                          Navigator.of(context).pop(true);
                          Navigator.pushReplacementNamed(context, Routes.login);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(245, 48),
                        alignment: Alignment.center,
                        backgroundColor: primary600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                Navigator.pushNamed(
                  context,
                  Routes.termPage,
                  arguments: LinkArguments(link: 'https://spot-harpymimus-46b.notion.site/LINKPOOL-f0c6fd16eecf4c8c96bb317421ecc174'),
                );
                break;
              }
            case '도움말':
              {
                Navigator.pushNamed(
                  context,
                  Routes.termPage,
                  arguments: LinkArguments(link: 'https://spot-harpymimus-46b.notion.site/LINKPOOL-cf1f4d836d764b889a68f79d989cd624'),
                );
                break;
              }
            case '로그아웃':
              {
                showPopUp(
                  title: '로그아웃 완료',
                  content: '계정이 로그아웃 되었어요',
                  context: context,
                  callback: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                );

                // Navigator.popAndPushNamed(context, Routes.login);
                break;
              }
            case '회원탈퇴':
              {
                showPopUp(
                  title: '정말 탈퇴하시겠어요?',
                  content: '지금 탈퇴하면 그동안 모은 링크가 사라져요',
                  context: context,
                  callback: () async {},
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
                  fontFamily: R_Font.PRETENDARD,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
