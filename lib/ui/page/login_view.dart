import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/resource.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
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
  static const google = 'Google';
  static const apple = 'Apple';
  static const loginText = '로 로그인';

  @override
  void initState() {
    super.initState();

    BlocProvider.of<LoginCubit>(context).stream.listen(_moveToSignUpPage);
  }

  void _moveToSignUpPage(String? event) {
    if (event != null) {
      Navigator.pushNamed(context, Routes.signUpNickname);
      //Navigator.pushNamed(context, Routes.signUp, arguments: event);
    }
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
                        color: loginTextGreyColor,
                      ),
                    ).bold().roboto(),
                  ),
                  const Text(
                    loginText,
                    style: TextStyle(
                      fontSize: 20,
                      color: loginTextGreyColor,
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
