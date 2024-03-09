import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/user/user.dart' as custom;
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/buttons/apple/apple_login_button.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => LoginCubit(),
      child: Scaffold(
        key: const Key('LoginView'),
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
    Email.login(
      email,
      link,
      onSuccess: (data) {
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
            () => showBottomToast(
              context: context,
              '가입된 계정이 없어 회원 가입 화면으로 이동합니다.',
            ),
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
      onError: (msg) {
        context.read<LoginCubit>().showError('이메일 로그인/회원가입 실패');
      },
      onFail: () {
        context.read<LoginCubit>().showError('이메일 로그인/회원가입 실패');
      },
    );
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 33.h,
                      left: 24.w,
                      right: 24.w,
                      bottom: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 37.h),
                          child: Stack(
                            children: [
                              Center(
                                child: const Text('서비스 이용을 위한 동의')
                                    .bold()
                                    .fontSize(21.sp),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 24.r,
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
                              padding: EdgeInsets.only(bottom: 28.h),
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.r),
                                        ),
                                        border: Border.all(
                                          width: 0.w,
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(2.r),
                                        child: firstCheck
                                            ? Icon(
                                                Icons.check,
                                                size: 18.r,
                                                color: Colors.white,
                                              )
                                            : Icon(
                                                Icons.check,
                                                size: 18.r,
                                                color: grey300,
                                              ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 11.w),
                                    child: const Text('전체 동의')
                                        .bold()
                                        .fontSize(17.sp),
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
                                  padding: EdgeInsets.only(bottom: 15.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Padding(
                                          padding: EdgeInsets.all(2.r),
                                          child: secondCheck
                                              ? Icon(
                                                  Icons.check,
                                                  size: 18.r,
                                                  color: primary800,
                                                )
                                              : Icon(
                                                  Icons.check,
                                                  size: 18.r,
                                                  color: grey300,
                                                ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsets.only(left: 11.w),
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
                                  padding: EdgeInsets.only(bottom: 28.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Padding(
                                          padding: EdgeInsets.all(2.r),
                                          child: thirdCheck
                                              ? Icon(
                                                  Icons.check,
                                                  size: 18.r,
                                                  color: primary800,
                                                )
                                              : Icon(
                                                  Icons.check,
                                                  size: 18.r,
                                                  color: grey300,
                                                ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsets.only(left: 11.w),
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
                        Padding(
                          padding: EdgeInsets.only(bottom: 54.h),
                          child: Builder(
                            builder: (context) {
                              final allChecked =
                                  firstCheck && secondCheck && thirdCheck;
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.fromHeight(55.h),
                                  backgroundColor:
                                      allChecked ? primary800 : secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: secondary,
                                  disabledForegroundColor: Colors.white,
                                ),
                                onPressed: allChecked
                                    ? () {
                                        Navigator.pop(context);
                                        Future.microtask(
                                          () => Navigator.pushNamed(
                                            context,
                                            Routes.signUpNickname,
                                            arguments: user,
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(
                                  '약관동의',
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
          buildAppleLoginButton(context),
          SizedBox(height: 26.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                key: const Key('KakaoLoginButton'),
                onTap: () => context.read<LoginCubit>().login(LoginType.kakao),
                child: Assets.images.kakaoIcon.image(),
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                key: const Key('NaverLoginButton'),
                onTap: () => context.read<LoginCubit>().login(LoginType.naver),
                child: Assets.images.naverIcon.image(),
              ),
            ],
          ),
          SizedBox(height: 53.h),
          InkWell(
            key: const Key('EmailLoginButton'),
            onTap: () => Navigator.pushNamed(context, Routes.emailLogin),
            child: Text(
              '이메일로 로그인',
              style: TextStyle(
                color: grey400,
                fontWeight: FontWeight.w500,
                fontSize: 15.sp,
                letterSpacing: -0.1.w,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          InkWell(
            key: const Key('SignedUserLoginButton'),
            onTap: () =>
                context.read<LoginCubit>().login(LoginType.signedLoginTest),
            child: Container(width: 1, height: 1, color: Colors.transparent),
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
            Assets.images.loginLogo.image(),
            SizedBox(
              height: 14.h,
            ),
            SvgPicture.asset(Assets.images.loginLogoText),
          ],
        ),
      ),
    );
  }

  Widget buildGoogleLoginButton(BuildContext context) {
    return GestureDetector(
      key: const Key('GoogleLoginButton'),
      onTap: () => context.read<LoginCubit>().login(LoginType.google),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8.r)),
            border: Border.all(color: const Color(0xffd9dee0)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Assets.images.login.googleIcon.image(),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 19.sp,
                        color: greyLoginText,
                        letterSpacing: -0.1.w,
                      ),
                    ).bold().roboto(),
                  ),
                  Text(
                    '로 로그인',
                    style: TextStyle(
                      fontSize: 19.sp,
                      color: greyLoginText,
                      letterSpacing: -0.1.w,
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
    return Column(
      children: [
        SizedBox(height: 12.h),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          child: SignInWithAppleButton(
            key: const Key('AppleLoginButton'),
            onPressed: () => context.read<LoginCubit>().login(LoginType.apple),
          ),
        ),
      ],
    );
  }
}
