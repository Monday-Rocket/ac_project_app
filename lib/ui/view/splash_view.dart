import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController firstAnimationController;
  late AnimationController secondAnimationController;

  @override
  void initState() {
    setAnimationController();
    Future.delayed(const Duration(milliseconds: 1500), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FolderApi().bulkSave().then((_) {
          Navigator.pushReplacementNamed(
            context,
            Routes.home,
            arguments: {
              'index': 0,
            },
          );
        });
      } else {
        unawaited(Navigator.pushReplacementNamed(context, Routes.login));
      }
    });
    super.initState();
  }

  void setAnimationController() {
    firstAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    );

    secondAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    );

    firstAnimationController.forward();
    Timer(
      const Duration(milliseconds: 300),
      () => secondAnimationController.forward(),
    );
    secondAnimationController.forward();
  }

  @override
  void dispose() {
    firstAnimationController.dispose();
    secondAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: splashColor,
      body: Stack(
        children: [
          buildWhiteIcon(),
          buildBottomWave(width),
          buildWhiteAppName(),
        ],
      ),
    );
  }

  Center buildWhiteAppName() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(secondAnimationController),
          child: FadeTransition(
            opacity: secondAnimationController,
            child: SvgPicture.asset(
              'assets/images/app_name.svg',
              width: 135,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }

  Align buildBottomWave(double width) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FadeTransition(
        opacity: secondAnimationController,
        child: Image.asset(
          'assets/images/wave_back.png',
          fit: BoxFit.contain,
          width: width,
        ),
      ),
    );
  }

  Center buildWhiteIcon() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(firstAnimationController),
          child: FadeTransition(
            opacity: firstAnimationController,
            child: Image.asset(
              'assets/images/app_white_icon.png',
            ),
          ),
        ),
      ),
    );
  }
}
