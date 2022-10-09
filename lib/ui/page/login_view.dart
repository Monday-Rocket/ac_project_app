import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/resource.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/models/login/login_type.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const google = 'Google';
  static const apple = 'Apple';
  static const loginText = '로 로그인';

  bool firstCheck = false;
  bool secondCheck = false;
  bool thirdCheck = false;

  bool secondOpened = false;
  bool thirdOpened = false;

  ScrollController secondController = ScrollController();
  ScrollController thirdController = ScrollController();

  @override
  void initState() {
    BlocProvider.of<LoginCubit>(context).stream.listen(_moveToSignUpPage);
    // 바로 사용 동의 화면 볼 때 사용
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _moveToSignUpPage(SignUpType.newUser);
    // });

    super.initState();
  }

  Future<void> _moveToSignUpPage(SignUpType? signUpType) async {
    if (signUpType == null) {
      Log.d('first');
    } else if (signUpType == SignUpType.newUser) {
      // 1. 서비스 이용 동의
      // 2. 가입 화면으로 이동
      final result = await showModalBottomSheet<bool?>(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Wrap(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 33, left: 24, right: 24),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 37),
                            child: Stack(
                              children: [
                                Center(
                                  child: const Text('서비스 이용을 위한 동의')
                                      .bold()
                                      .fontSize(21),
                                ),
                                Container(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          buildFirstCheckBox(setState),
                          const SizedBox(
                            height: 28,
                          ),
                          buildSecondCheckBox(setState),
                          buildThirdCheckBox(setState),
                          const SizedBox(
                            height: 28,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 54),
                            child: Builder(
                              builder: (context) {
                                final allChecked =
                                    firstCheck && secondCheck && thirdCheck;
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(55),
                                    backgroundColor: allChecked
                                        ? purpleMain
                                        : purpleUnchecked,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: allChecked
                                      ? () => Navigator.pushNamed(context, Routes.signUpNickname)
                                      : null,
                                  child: const Text(
                                    '약관동의',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textWidthBasis: TextWidthBasis.parent,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
      if (result != true) {
        if (!mounted) return;
        context.read<LoginCubit>().initialize();
      } else {
        if (!mounted) return;
        unawaited(Navigator.pushNamed(context, Routes.signUpNickname));
      }
    } else {
      unawaited(goHomeScreen(context));
    }
  }

  Future<Object?> goHomeScreen(BuildContext context) {
    return Navigator.pushNamed(
                                          context,
                                          Routes.home,
                                        );
  }

  Widget buildThirdCheckBox(StateSetter setState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      thirdCheck = !thirdCheck;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: thirdCheck
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: purpleMain,
                            )
                          : const Icon(
                              Icons.check,
                              size: 18,
                              color: greyUncheckedIcon,
                            ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      thirdOpened = !thirdOpened;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: const Text('서비스 이용방침 (필수)')
                        .weight(FontWeight.w500)
                        .fontSize(15),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                setState(() {
                  thirdOpened = !thirdOpened;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: thirdOpened
                      ? const Icon(
                          Icons.keyboard_arrow_down_sharp,
                          size: 20,
                          color: greyArrow,
                        )
                      : const Icon(
                          Icons.keyboard_arrow_right_sharp,
                          size: 20,
                          color: greyArrow,
                        ),
                ),
              ),
            ),
          ],
        ),
        AnimatedContainer(
          height: thirdOpened ? 15 : 0,
          duration: const Duration(milliseconds: 150),
        ),
        AnimatedContainer(
          height: thirdOpened ? 140 : 0,
          duration: const Duration(milliseconds: 150),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: blueBack,
          ),
          child: thirdOpened
              ? Scrollbar(
                  controller: thirdController,
                  child: SingleChildScrollView(
                    controller: thirdController,
                    padding: EdgeInsets.zero,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 24, top: 14, right: 24),
                      child: Text(secondCheckText),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget buildSecondCheckBox(StateSetter setState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      secondCheck = !secondCheck;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: secondCheck
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: purpleMain,
                            )
                          : const Icon(
                              Icons.check,
                              size: 18,
                              color: greyUncheckedIcon,
                            ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      secondOpened = !secondOpened;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: const Text('개인정보 처리방침 (필수)')
                        .weight(FontWeight.w500)
                        .fontSize(15),
                  ),
                ),
              ],
            ),
            Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    secondOpened = !secondOpened;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: secondOpened
                        ? const Icon(
                            Icons.keyboard_arrow_down_sharp,
                            size: 20,
                            color: greyArrow,
                          )
                        : const Icon(
                            Icons.keyboard_arrow_right_sharp,
                            size: 20,
                            color: greyArrow,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        AnimatedContainer(
          height: secondOpened ? 140 : 0,
          duration: const Duration(milliseconds: 150),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: blueBack,
          ),
          child: secondOpened
              ? Scrollbar(
                  controller: secondController,
                  child: SingleChildScrollView(
                    controller: secondController,
                    padding: EdgeInsets.zero,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 24, top: 14, right: 24),
                      child: Text(firstCheckText),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AnimatedContainer(
          height: secondOpened ? 15 : 0,
          duration: const Duration(milliseconds: 150),
        ),
      ],
    );
  }

  Row buildFirstCheckBox(StateSetter setState) {
    return Row(
      children: [
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                firstCheck = !firstCheck;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: firstCheck ? purpleMain : greyUnchecked,
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
                        color: greyUncheckedIcon,
                      ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: const Text('전체 동의').bold().fontSize(17),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              buildAppImage(),
              buildLoginButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Align buildLoginButtons(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 37),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildGoogleLoginButton(context),
            const SizedBox(height: 12),
            buildAppleLoginButton(context),
          ],
        ),
      ),
    );
  }

  Expanded buildAppImage() {
    return const Expanded(
      child: Center(
        child: Icon(
          Icons.apple,
          size: 140,
        ),
      ),
    );
  }

  GestureDetector buildGoogleLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<LoginCubit>().login(LoginType.google),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: const Color(0xffd9dee0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(R.ASSETS_IMAGES_LOGIN_GOOGLEICON_PNG),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      google,
                      style: TextStyle(
                        fontSize: 20,
                        color: greyLoginText,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    loginText,
                    style: TextStyle(
                      fontSize: 20,
                      color: greyLoginText,
                    ),
                  ).bold().pretendard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAppleLoginButton(BuildContext context) {
    if (Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => context.read<LoginCubit>().login(LoginType.apple),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: const Color(0xffd9dee0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(R.ASSETS_IMAGES_LOGIN_APPLEICON_PNG),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      apple,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    loginText,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ).bold().pretendard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
