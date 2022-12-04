// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class EmailSignUpView extends StatefulWidget {
  const EmailSignUpView({super.key});

  @override
  State<EmailSignUpView> createState() => _EmailSignUpViewState();
}

class _EmailSignUpViewState extends State<EmailSignUpView>
    with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();
  bool buttonState = false;

  String emailString = '';

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: KeyboardVisibilityBuilder(
        builder: (context, visible) {
          return Scaffold(
            appBar: buildBackAppBar(context),
            body: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      '가입에 필요한\n정보를 입력해주세요.',
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
                          autofocus: true,
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
                              borderSide: BorderSide(color: primary800, width: 2),
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
                  ],
                ),
              ),
            ),
            bottomSheet: Container(
              margin: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: getBottomMargin(visible),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: primary800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: secondary,
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: buttonState ? () => Email.send(emailString) : null,
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  double getBottomMargin(bool visible) {
    return visible ? 16 : 37;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        Log.d('resumed');
        unawaited(retrieveDynamicLinkAndSignIn(fromColdState: false));
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

  Future<bool> retrieveDynamicLinkAndSignIn({
    required bool fromColdState,
  }) async {
    PendingDynamicLinkData? dynamicLinkData;
    Uri? deepLink;

    if (fromColdState) {
      dynamicLinkData = await FirebaseDynamicLinks.instance.getInitialLink();
      if (dynamicLinkData != null) {
        deepLink = dynamicLinkData.link;
      }
    } else {
      dynamicLinkData = await FirebaseDynamicLinks.instance.onLink.first;
      deepLink = dynamicLinkData.link;
    }

    if (deepLink == null) {
      return false;
    }

    final validLink =
        FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString());

    if (validLink) {
      final continueUrl = deepLink.queryParameters['continueUrl'] ?? '';
      final email = Uri.parse(continueUrl).queryParameters['email'] ?? '';
      _handleLink(email, deepLink.toString());
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleLink(String email, String link) {
    Email.login(email, link).then((isSuccess) async {
      if (isSuccess) {
        final user = await UserApi().postUsers();

        user.when(
          success: (data) {
            Navigator.pushReplacementNamed(
              context,
              Routes.terms,
            );
          },
          error: (msg) {
            Log.e('login fail');
          },
        );
      } else {
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
    } else {
      return null;
    }
  }
}
