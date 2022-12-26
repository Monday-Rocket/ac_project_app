import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/resource.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/models/user/user.dart' as custom;
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

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
            child: BlocBuilder<LoginCubit, LoginUserState>(
              builder: (loginContext, state) {
                if (state is LoginLoadingState) {
                  return const CircularProgressIndicator();
                } else if (state is LoginErrorState) {
                  showErrorBanner(loginContext, state.message);
                } else if (state is LoginLoadedState) {
                  moveToNext(context, loginContext, state.user);
                } else if (state is LoginInitialState) {
                  retrieveDynamicLinkAndSignIn(loginContext);
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

  void retrieveDynamicLinkAndSignIn(BuildContext context) {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      context.read<LoginCubit>().loading();

      final deepLink = dynamicLinkData.link;
      final validLink =
          FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString());

      if (validLink) {
        final continueUrl = deepLink.queryParameters['continueUrl'] ?? '';
        final email = Uri.parse(continueUrl).queryParameters['email'] ?? '';
        _handleLink(email, deepLink.toString(), context);
      } else {
        context.read<LoginCubit>().showError('이메일 로그인/회원가입 실패');
      }
    });
  }

  void _handleLink(String email, String link, BuildContext context) {
    Email.login(email, link).then((isSuccess) async {
      if (isSuccess) {
        final user = await UserApi().postUsers();

        user.when(
          success: (data) {
            if (data.is_new ?? false) {
              Navigator.pushNamed(
                context,
                Routes.terms,
                arguments: {
                  'user': data,
                },
              ).then((_) => context.read<LoginCubit>().showNothing());
              Future.delayed(
                const Duration(milliseconds: 500),
                () => showBottomToast('가입된 계정이 없어 회원 가입 화면으로 이동합니다.'),
              );
            } else {
              ShareDataProvider.loadServerData();
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (_) => false,
                arguments: {'index': 0},
              );
            }
          },
          error: (msg) {
            context.read<LoginCubit>().showError('이메일 로그인/회원가입 실패');
            Log.e('login fail');
          },
        );
      } else {
        context.read<LoginCubit>().showError('이메일 로그인/회원가입 실패');
        Log.e('login fail');
      }
    });
  }

  void showErrorBanner(BuildContext context, String message) {
    Log.e('로그인 에러: $message');
  }

  Future<void> moveToNext(
    BuildContext parentContext,
    BuildContext context,
    custom.User user,
  ) async {
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
              Navigator.pushNamed(parentContext, Routes.signUpNickname),
            );
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
                    padding: const EdgeInsets.only(
                      top: 33,
                      left: 24,
                      right: 24,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: ColoredBox(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color:
                                            firstCheck ? primary800 : grey100,
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
                                    child:
                                        const Text('전체 동의').bold().fontSize(17),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
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
                                      Row(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 11),
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
                          ],
                        ),
                        Column(
                          children: [
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
                                  padding: const EdgeInsets.only(bottom: 28),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
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
                                      Row(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 11),
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
              onPressed: () => Navigator.pushNamed(context, Routes.emailLogin),
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
            onTap: () => Navigator.pushNamed(context, Routes.emailSignUp),
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
          const SizedBox(height: 12),
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
