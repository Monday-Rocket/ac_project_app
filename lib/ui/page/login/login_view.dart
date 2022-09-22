import 'package:ac_project_app/ui/page/login/login_controller.dart';
import 'package:ac_project_app/ui/page/login/login_type.dart';
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                    color: !isDarkMode ? Colors.black : Colors.white,
                    width: 2,
                  ),
                  color: Colors.white,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '먼데이 로켓 로그인',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: GestureDetector(
                              onTap: () => controller.login(LoginType.google),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'images/google_icon.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Google Login'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: controller.getShareData,
                  child: Container(
                    color: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('웹에서 가져온 데이터 보기'),
                    ),
                  ),
                ),
              ),
              GetBuilder<LoginController>(
                builder: (c) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      color: Colors.black,
                      height: 100,
                      child: ListView.builder(
                        itemCount: c.shareDataList.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              c.shareDataList[index],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
