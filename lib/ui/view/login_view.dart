import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/resource.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/user_state.dart';
import 'package:ac_project_app/models/user/user.dart' as custom;
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: BlocBuilder<LoginCubit, UserState>(
              builder: (loginContext, state) {
                if (state is LoadingState) {
                  return const CircularProgressIndicator();
                } else if (state is ErrorState) {
                  showErrorBanner(loginContext);
                } else if (state is LoadedState) {
                  moveToNext(context, loginContext, state.user);
                }
                return Column(
                  children: [
                    buildAppImage(),
                    buildLoginButtons(loginContext),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void showErrorBanner(BuildContext context) {
    Fluttertoast.showToast(
      msg: '                로그인 실패                ',
      gravity: ToastGravity.TOP,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: grey900,
      textColor: Colors.white,
      fontSize: 13,
    );
  }

  Future<void> moveToNext(BuildContext parentContext, BuildContext context,
      custom.User user) async {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (user.is_new ?? false) {
        // 1. 서비스 이용 동의
        // 2. 가입 화면으로 이동
        getServiceApproval(parentContext, user).then((result) {
          if (result != true) {
            // 초기화
            context.read<LoginCubit>().initialize();
          } else {
            // 회원가입 이동
            unawaited(
                Navigator.pushNamed(parentContext, Routes.signUpNickname));
          }
        });
      } else {
        unawaited(
          Navigator.pushReplacementNamed(
            parentContext,
            Routes.home,
            arguments: {
              'index': 0,
            },
          ),
        );
      }
    });
  }

  Future<bool?> getServiceApproval(
    BuildContext context,
    custom.User user,
  ) async {
    return showModalBottomSheet<bool?>(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        var firstCheck = false;
        var secondCheck = false;
        var thirdCheck = false;

        var secondOpened = false;
        var thirdOpened = false;
        return Wrap(
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                final secondController = ScrollController();
                final thirdController = ScrollController();
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 33,
                      left: 24,
                      right: 24,
                    ),
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
                        Row(
                          children: [
                            Center(
                              child: InkWell(
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
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 11),
                              child: const Text('전체 동의').bold().fontSize(17),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        Column(
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
                                          firstCheck =
                                              secondCheck && thirdCheck;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
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
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          secondOpened = !secondOpened;
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 11),
                                        child: const Text('개인정보 처리방침')
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
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: secondOpened
                                            ? const Icon(
                                                Icons.keyboard_arrow_down_sharp,
                                                size: 20,
                                                color: grey500,
                                              )
                                            : const Icon(
                                                Icons
                                                    .keyboard_arrow_right_sharp,
                                                size: 20,
                                                color: grey500,
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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                color: grey100,
                              ),
                              child: secondOpened
                                  ? Scrollbar(
                                      controller: secondController,
                                      child: SingleChildScrollView(
                                        controller: secondController,
                                        padding: EdgeInsets.zero,
                                        child: const Padding(
                                          padding: EdgeInsets.only(
                                            left: 24,
                                            top: 14,
                                            right: 24,
                                          ),
                                          child: Text(
                                            firstCheckText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: grey600,
                                            ),
                                          ),
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
                        ),
                        Column(
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
                                          firstCheck =
                                              secondCheck && thirdCheck;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
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
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          thirdOpened = !thirdOpened;
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 11),
                                        child: const Text('서비스 이용방침')
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
                                              color: grey500,
                                            )
                                          : const Icon(
                                              Icons.keyboard_arrow_right_sharp,
                                              size: 20,
                                              color: grey500,
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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                color: grey100,
                              ),
                              child: thirdOpened
                                  ? Scrollbar(
                                      controller: thirdController,
                                      child: SingleChildScrollView(
                                        controller: thirdController,
                                        padding: EdgeInsets.zero,
                                        child: const Padding(
                                          padding: EdgeInsets.only(
                                            left: 24,
                                            top: 14,
                                            right: 24,
                                          ),
                                          child: Text(
                                            secondCheckText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: grey600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
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
                                  backgroundColor:
                                      allChecked ? primary800 : secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: secondary,
                                  disabledForegroundColor: Colors.white,
                                ),
                                onPressed: allChecked
                                    ? () => Navigator.pushNamed(
                                          context,
                                          Routes.signUpNickname,
                                          arguments: user,
                                        )
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
  }

  Align buildLoginButtons(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          buildGoogleLoginButton(context),
          const SizedBox(height: 12),
          buildAppleLoginButton(context),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: primary700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Navigator.popAndPushNamed(context, Routes.emailLogin),
              child: const Text(
                '일반 로그인',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(height: 21),
          InkWell(
            onTap: () => Navigator.popAndPushNamed(context, Routes.emailSignUp),
            child: const Text(
              '이메일로 회원가입',
              style: TextStyle(
                color: grey400,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Expanded buildAppImage() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/login_logo.png',
            ),
            const SizedBox(
              height: 14,
            ),
            SvgPicture.asset('assets/images/login_logo_text.svg'),
          ],
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
            padding: const EdgeInsets.symmetric(vertical: 21),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(R.ASSETS_IMAGES_LOGIN_GOOGLEICON_PNG),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 15,
                        color: greyLoginText,
                        letterSpacing: -0.1,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    '로 로그인',
                    style: TextStyle(
                      fontSize: 15,
                      color: greyLoginText,
                      letterSpacing: -0.1,
                    ),
                  ).bold(),
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
            padding: const EdgeInsets.only(top: 19, bottom: 23),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(R.ASSETS_IMAGES_LOGIN_APPLEICON_PNG),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      'Apple',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    '로 로그인',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ).bold(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
