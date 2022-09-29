import 'dart:io';

import 'package:ac_project_app/cubits/login/apple_login_cubit.dart';
import 'package:ac_project_app/cubits/login/google_login_cubit.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';

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
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 300),
                child: const Icon(
                  Icons.apple,
                  size: 200,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: SignInButton(
                  Buttons.Google,
                  onPressed: context.read<GoogleLoginCubit>().login,
                ),
              ),
              buildAppleLoginButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppleLoginButton(BuildContext context) {
    if (Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 8,
      ),
      child: SignInButton(
        Buttons.AppleDark,
        onPressed: context.read<AppleLoginCubit>().login,
      ),
    );
  }
}
