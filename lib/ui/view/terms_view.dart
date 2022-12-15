import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:flutter/material.dart';
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
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '링풀 서비스\n이용약관에 동의해주세요.',
                  style: TextStyle(
                    fontSize: 24,
                    color: grey900,
                    fontWeight: FontWeight.bold,
                    height: 34 / 24,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 40),
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
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            border: Border.all(
                              width: 0,
                              color: Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: firstCheck
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: grey300,
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: const Text('전체 동의').bold().fontSize(17),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 21),
                  child: const Divider(
                    height: 1,
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
                      padding: const EdgeInsets.only(top: 19, bottom: 9),
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
                                  padding: const EdgeInsets.all(2),
                                  child: secondCheck
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: primary800,
                                        )
                                      : const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: grey300,
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 11,
                                ),
                                child: const Text('개인정보 수집 및 이용 동의')
                                    .weight(FontWeight.w500)
                                    .fontSize(15),
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
                                    .fontSize(15),
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
                      padding: const EdgeInsets.only(top: 9),
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
                                  padding: const EdgeInsets.all(2),
                                  child: thirdCheck
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: primary800,
                                        )
                                      : const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: grey300,
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 11,
                                ),
                                child: const Text('서비스 이용약관')
                                    .weight(FontWeight.w500)
                                    .fontSize(15),
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
                                    .fontSize(15),
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
