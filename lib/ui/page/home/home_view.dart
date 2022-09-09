import 'package:ac_project_app/ui/page/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: GetBuilder<HomeController>(
            builder: (c) {
              if (c.greeting != null) {
                return Text(c.greeting!, style: const TextStyle(fontSize: 24));
              } else {
                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    color: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
