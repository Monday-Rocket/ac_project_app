import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsView extends StatefulWidget {
  const TermsView({super.key});

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  bool buttonState = false;

  bool firstCheck = false;
  bool secondCheck = false;
  bool thirdCheck = false;

  bool secondOpened = false;
  bool thirdOpened = false;

  final secondController = ScrollController();
  final thirdController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final user = getArguments(context)['user'] as User?;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: buildBackAppBar(context),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.w),
                Text(
                  '링풀 서비스\n이용약관에 동의해주세요.',
                  style: TextStyle(
                    fontSize: 24.sp,
                    color: grey900,
                    fontWeight: FontWeight.bold,
                    height: 34 / 24,
                    letterSpacing: -0.3.w,
                  ),
                ),
                SizedBox(height: 40.w),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      firstCheck = !firstCheck;
                      if (firstCheck) {
                        secondCheck = true;
                        thirdCheck = true;
                      } else {
                        secondCheck = false;
                        thirdCheck = false;
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: firstCheck ? primary800 : grey100,
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.w),
                            ),
                            border: Border.all(
                              width: 0,
                              color: Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(2.w),
                            child: firstCheck
                                ? Icon(
                                    Icons.check,
                                    size: 18.w,
                                    color: Colors.white,
                                  )
                                : Icon(
                                    Icons.check,
                                    size: 18.w,
                                    color: grey300,
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 11.w),
                        child: const Text('전체 동의').bold().fontSize(17.sp),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 21.w),
                  child: Divider(
                    height: 1.w,
                    color: greyTab,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      secondCheck = !secondCheck;
                      firstCheck = secondCheck && thirdCheck;
                    });
                  },
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.only(top: 19.w, bottom: 9.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 200,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: secondCheck
                                      ? Icon(
                                          Icons.check,
                                          size: 18.w,
                                          color: primary800,
                                        )
                                      : Icon(
                                          Icons.check,
                                          size: 18.w,
                                          color: grey300,
                                        ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 11.w,
                                ),
                                child: const Text('개인정보 수집 및 이용 동의')
                                    .weight(FontWeight.w500)
                                    .fontSize(15.sp),
                              ),
                              GestureDetector(
                                onTap: () => launchUrl(
                                  Uri.parse(
                                    approveFirstLink,
                                  ),
                                  mode: LaunchMode
                                      .externalApplication,
                                ),
                                child: const Text('[보기]')
                                    .weight(FontWeight.w500)
                                    .fontSize(15.sp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      thirdCheck = !thirdCheck;
                      firstCheck = secondCheck && thirdCheck;
                    });
                  },
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.only(top: 9.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 200,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: thirdCheck
                                      ? Icon(
                                          Icons.check,
                                          size: 18.w,
                                          color: primary800,
                                        )
                                      : Icon(
                                          Icons.check,
                                          size: 18.w,
                                          color: grey300,
                                        ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 11.w,
                                ),
                                child: const Text('서비스 이용약관')
                                    .weight(FontWeight.w500)
                                    .fontSize(15.sp),
                              ),
                              GestureDetector(
                                onTap: () => launchUrl(
                                  Uri.parse(
                                    approveSecondLink,
                                  ),
                                  mode: LaunchMode
                                      .externalApplication,
                                ),
                                child: const Text('[보기]')
                                    .weight(FontWeight.w500)
                                    .fontSize(15.sp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: buildBottomSheetButton(
        context: context,
        text: '약관동의',
        onPressed: firstCheck && secondCheck && thirdCheck
            ? () => Navigator.pushNamed(
                  context,
                  Routes.signUpNickname,
                  arguments: user,
                )
            : null,
      ),
    );
  }
}
