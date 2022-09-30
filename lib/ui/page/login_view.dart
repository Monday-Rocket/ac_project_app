import 'dart:io';

import 'package:ac_project_app/const/resource.dart';
import 'package:ac_project_app/cubits/login/apple_login_cubit.dart';
import 'package:ac_project_app/cubits/login/google_login_cubit.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();

    BlocProvider.of<GoogleLoginCubit>(context).stream.listen(_moveToSignUpPage);
    BlocProvider.of<AppleLoginCubit>(context).stream.listen(_moveToSignUpPage);
  }

  void _moveToSignUpPage(String? event) {
    if (event != null) {
      Navigator.popAndPushNamed(context, Routes.signUp, arguments: event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Icon(
                    Icons.apple,
                    size: 140,
                  ),
                ),
              ),
              Align(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector buildGoogleLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: context.read<GoogleLoginCubit>().login,
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
                        color: Color(0xff757575),
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    '로 로그인',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff757575),
                    ),
                  ).bold().pretendard()
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
      onTap: context.read<AppleLoginCubit>().login,
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
                  ).bold().pretendard()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
