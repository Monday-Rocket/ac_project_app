import 'package:flutter/material.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {

    final token = ModalRoute.of(context)!.settings.arguments as String? ?? 'null';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Text(token, style: const TextStyle(color: Colors.black),),
        ),
      ),
    );
  }
}
