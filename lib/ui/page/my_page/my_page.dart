// ignore_for_file: avoid_positional_boolean_parameters
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 46, bottom: 6),
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                Container(
                  child: SvgPicture.asset(
                    'assets/images/ic_change.svg',
                  ),
                  padding: EdgeInsets.all(4),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '마이페이지',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Color(0xff0e0e0e),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 47,
          ),
          MenuList(context),
        ],
      ),
    );
  }

  Widget MenuList(BuildContext context) {

    void showPopUp({
      required String title,
      required String content,
      bool icon = false,
      bool isLogout = false,
      bool isLeave = false,
    }) {
      showDialog(
        barrierDismissible: true,
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: icon ? 14 : 16,
                      ),
                      if (icon)
                        Icon(
                          Icons.error,
                          color: primary800,
                          size: 27,
                        ),
                      SizedBox(
                        height: icon ? 7 : 0,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: R_Font.PRETENDARD,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(content, textAlign: TextAlign.center),
                      SizedBox(
                        height: 32,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text('확인'),
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(245, 48),
                          alignment: Alignment.center,
                          backgroundColor: primary600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                      icon: Icon(
                        Icons.close,
                      )),
                ),
              ],
            ),
          );
        },
      );
    }

    Widget DivisionLine({double size = 4}) {
      return Container(
        height: size,
        width: MediaQuery.of(context).size.width,
        color: grey200,
      );
    }

    Widget MenuItem(String menuName,
        {bool arrow = true, Color color = grey900}) {
      return InkWell(
        onTap: () {
          switch (menuName) {
            case '도움말':
              {
                Navigator.pushNamed(context, Routes.myLinkDetail);
                break;
              }
            case '이용 약관':
              {
                Navigator.pushNamed(
                  context,
                  Routes.termPage,
                  arguments: LinkArguments(link: 'https://www.naver.com'),
                );
                break;
              }
            case '개인정보 처리방침':
              {
                Navigator.pushNamed(
                  context,
                  Routes.termPage,
                  arguments: LinkArguments(link: 'https://www.daum.net'),
                );
                break;
              }
            case '로그아웃':
              {
                showPopUp(
                  title: '로그아웃 완료',
                  content: '계정이 로그아웃 되었어요',
                );

                // Navigator.popAndPushNamed(context, Routes.login);
                break;
              }
            case '회원탈퇴':
              {
                showPopUp(
                  title: '정말 탈퇴하시겠어요?',
                  content: '지금 탈퇴하면 그동안 모은 링크가 사라져요',
                  icon: true,
                );
                break;
              }
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
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
              if (arrow) Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
