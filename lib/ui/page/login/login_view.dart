import 'package:ac_project_app/ui/page/login/login_controller.dart';
import 'package:ac_project_app/ui/page/login/login_type.dart';
import 'package:ac_project_app/ui/widget/buttons/apple/apple_login_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                color: !isDarkMode ? Colors.black : Colors.white,
                width: 2,
              ),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '먼데이 로켓',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: SizedBox(
                      width: Get.width / 2,
                      child: SignInWithAppleButton(
                        onPressed: () => controller.login(LoginType.apple),
                        text: 'Apple Login',
                        iconAlignment: IconAlignment.left,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.login(LoginType.google),
                    child: const ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Google Login'),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.login(LoginType.kakao),
                    child: const ColoredBox(
                      color: Color(0xFFCEBB19),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Kakao Login'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
