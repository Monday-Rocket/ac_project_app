import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/resource.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/user_state.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with WidgetsBindingObserver {
  PendingDynamicLinkData? initialLink;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: BlocBuilder<LoginCubit, UserState>(
              builder: (loginContext, state) {
                if (state is LoadingState) {
                  return const CircularProgressIndicator();
                } else if (state is ErrorState) {
                  showErrorBanner(loginContext);
                } else if (state is LoadedState) {
                  _moveToSignUpPage(loginContext, state.user);
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

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initDynamicLinks();
    super.initState();
  }

  Future<void> initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen(
      (dynamicLink) {
        final deepLink = dynamicLink.link;
        _handleLink(deepLink);
      },
      onError: (e) async {
        Log.e('onLinkError');
      },
    );
    final data = await FirebaseDynamicLinks.instance.getInitialLink();
    final deepLink = data?.link;
    Log.i('deepLink: $deepLink');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleLink(Uri link) async {
    final result = await Email.login('ts4840644804@gmail.com', link.toString());
    if (result) {
      final user = await UserApi().postUsers();

      user.when(
        success: (data) {
          _moveToSignUpPage(context, data);
        },
        error: (msg) {
          Log.e('로그인 에러');
        },
      );
    }
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

  Future<void> _moveToSignUpPage(BuildContext context, User user) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (user.is_new ?? false) {
        // 1. 서비스 이용 동의
        // 2. 가입 화면으로 이동
        unawaited(
          getServiceApproval(context, user).then((result) {
            if (result != true) {
              // 초기화
              context.read<LoginCubit>().initialize();
            } else {
              // 회원가입 이동
              unawaited(Navigator.pushNamed(context, Routes.signUpNickname));
            }
          }),
        );
      } else {
        unawaited(
          Navigator.pushReplacementNamed(
            context,
            Routes.home,
            arguments: {
              'index': 0,
            },
          ),
        );
      }
    });
  }

  Future<bool?> getServiceApproval(BuildContext context, User user) async {
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 37),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Email.send('ts4840644804@gmail.com'),
              child: const Text('테스트'),
            ),
            const SizedBox(height: 12),
            buildGoogleLoginButton(context),
            const SizedBox(height: 12),
            buildAppleLoginButton(context),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 22),
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
                        fontSize: 20,
                        color: greyLoginText,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    '로 로그인',
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
                      'Apple',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    '로 로그인',
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
