import 'dart:convert';

import 'package:ac_project_app/ui/page/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: GetBuilder<HomeController>(builder: (controller) {
            if (controller.state.isNotEmpty) {
              return Text(jsonEncode(controller.state.todayWeather));
            } else {
              return const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  color: Colors.red,
                ),
              );
            }
          },),
        ),
      ),
    );
  }
}
