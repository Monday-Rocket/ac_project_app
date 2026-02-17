// ignore_for_file: avoid_positional_boolean_parameters, non_constant_identifier_names

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

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
      ],
    );
  }
}
