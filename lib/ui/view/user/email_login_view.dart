// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/dialog.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmailLoginView extends StatefulWidget {
  const EmailLoginView({super.key});

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView>
    with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();
  bool buttonState = false;
  bool hasError = false;
  String emailString = '';
  bool isEmailSent = false;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: KeyboardVisibilityBuilder(
        builder: (context, visible) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: buildBackAppBar(context),
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    Text(
                      '로그인에 필요한\n정보를 입력해주세요.',
                      style: TextStyle(
                        fontSize: 24.sp,
                        color: grey900,
                        fontWeight: FontWeight.bold,
                        height: (34 / 24).h,
                        letterSpacing: -0.3.w,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 30.h, bottom: 23.h),
                      child: Form(
                        key: formKey,
                        child: TextFormField(
                          // autofocus: true.w,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w500,
                            color: blackBold,
                          ),
                          decoration: InputDecoration(
                            labelText: '이메일',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9097A3),
                              fontWeight: FontWeight.w500,
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: primary800, width: 2.w),
                            ),
                            errorStyle: const TextStyle(
                              color: redError,
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: redError, width: 2.w),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: greyTab, width: 2.w),
                            ),
                            contentPadding: EdgeInsets.zero,
                            suffix: buttonState
                                ? Icon(
                                    Icons.check,
                                    color: primary700,
                                    size: 16.r,
                                  )
                                : null,
                          ),
                          validator: validateEmail,
                          onSaved: (String? value) {
                            emailString = value ?? '';
                          },
                          onChanged: (String? value) {
                            if (value?.isEmpty ?? true) {
                              setState(() {
                                buttonState = false;
                              });
                            }
                            if (formKey.currentState != null) {
                              if (!formKey.currentState!.validate()) {
                                setState(() {
                                  buttonState = false;
                                });
                                return;
                              } else {
                                formKey.currentState!.save();
                                setState(() {
                                  buttonState = true;
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: grey100,
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.r),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 14.h, bottom: 12.h),
                              child: SvgPicture.asset(
                                Assets.images.emailNotice,
                              ),
                            ),
                            Text(
                              '인증메일을 받지 못하셨다면, 스팸 메일함을 확인하시거나\n소셜 로그인 방식으로 회원가입을 진행해 주세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                letterSpacing: -0.1.w,
                                fontWeight: FontWeight.w400,
                                color: grey500,
                                height: (17.5 / 13).h,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    color: grey400,
                                  ),
                                  constraints: BoxConstraints(
                                    minHeight: 34.h,
                                    maxWidth: 156.w,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '첫 화면으로 돌아가기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        letterSpacing: -0.1.w,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: keyboardHeight)
                  ],
                ),
              ),
            ),
            bottomSheet: buildBottomSheetButton(
              context: context,
              text: '로그인',
              keyboardVisible: visible,
              onPressed: buttonState
                  ? () {
                      if (isEmailSent) {
                        showBottomToast(context: context, '이미 이메일이 발송 되었습니다.');
                      } else {
                        Email.send(context, emailString, '로그인');
                        setState(() {
                          isEmailSent = true;
                        });
                      }
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  void backToLogin(BuildContext context) {
    unawaited(Navigator.pushNamed(context, Routes.login));
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        Log.d('resumed');
        retrieveDynamicLinkAndSignIn();
        break;
      case AppLifecycleState.paused:
        Log.d('paused');
        break;
      case AppLifecycleState.inactive:
        Log.d('inactive');
        break;
      case AppLifecycleState.detached:
        Log.d('detached');
        break;
    }
  }

  void retrieveDynamicLinkAndSignIn() {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      final deepLink = dynamicLinkData.link;
      final validLink =
          FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString());

      if (validLink) {
        final continueUrl = deepLink.queryParameters['continueUrl'] ?? '';
        final email = Uri.parse(continueUrl).queryParameters['email'] ?? '';
        _handleLink(email, deepLink.toString());
      }
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleLink(String email, String link) {
    hasError = true;
    Email.login(
      email,
      link,
      onSuccess: (data) {
        if (data.is_new ?? false) {
          Navigator.pushReplacementNamed(
            context,
            Routes.terms,
            arguments: {
              'user': data,
            },
          );
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
        setState(() {
          hasError = true;
        });
        Log.e('login fail');
      },
      onFail: () {
        showError(context);
        Log.e('login fail');
      },
    );
  }

  String? validateEmail(String? value) {
    const pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r'{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]'
        r'{0,253}[a-zA-Z0-9])?)*$';
    final regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      return '메일 형식으로 입력해주세요.';
    } else if (hasError) {
      setState(() {
        buttonState = true;
      });
      return '입력한 정보와 일치하는 계정이 없습니다.';
    } else {
      return null;
    }
  }
}
