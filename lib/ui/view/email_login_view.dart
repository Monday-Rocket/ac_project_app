// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
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
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 24,
                        color: grey900,
                        fontWeight: FontWeight.bold,
                        height: 34 / 24,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 30, bottom: 23),
                      child: Form(
                        key: formKey,
                        child: TextFormField(
                          // autofocus: true,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: blackBold,
                          ),
                          decoration: InputDecoration(
                            labelText: '이메일',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9097A3),
                              fontWeight: FontWeight.w500,
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: primary800, width: 2),
                            ),
                            errorStyle: const TextStyle(
                              color: redError,
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: redError, width: 2),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: greyTab, width: 2),
                            ),
                            contentPadding: EdgeInsets.zero,
                            suffix: buttonState
                                ? const Icon(
                                    Icons.check,
                                    color: primary700,
                                    size: 16,
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
                        showBottomToast('이미 이메일이 발송 되었습니다.');
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
    Email.login(email, link).then((isSuccess) async {
      if (isSuccess) {
        final user = await UserApi().postUsers();

        user.when(
          success: (data) {
            if (!mounted) {
              return;
            }
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
                () => showBottomToast('가입된 계정이 없어 회원 가입 화면으로 이동합니다.'),
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (_) => false,
                arguments: {'index': 0},
            );
            }
          },
          error: (msg) {
            setState(() {
              hasError = true;
            });
            Log.e('login fail');
          },
        );
      } else {
        showError(context);
        Log.e('login fail');
      }
    });
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
