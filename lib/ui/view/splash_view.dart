import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loginAfterAnimation();
    super.initState();
  }

  void _loginAfterAnimation() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      SharedPreferences.getInstance().then((SharedPreferences prefs) {
        final tutorial = prefs.getBool('tutorial2') ?? false;
        if (tutorial) {
          prefs.setBool('tutorial2', false);
          moveToTutorialView();
        } else {
          moveToNextView();
        }
      });
    });
  }

  void moveToNextView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserApi().postUsers().then((result) {
        result.when(
          success: (data) {
            if (data.is_new ?? false) {
              moveToLoginView();
            } else {
              ShareDataProvider.loadServerDataAtFirst();
              Navigator.pushReplacementNamed(
                context,
                Routes.home,
                arguments: {
                  'index': 0,
                },
              );
            }
          },
          error: (_) => moveToLoginView(),
        );
      });
    } else {
      moveToLoginView();
    }
  }

  void moveToLoginView() =>
      Navigator.pushReplacementNamed(context, Routes.login);

  void moveToTutorialView() =>
      Navigator.pushReplacementNamed(context, Routes.tutorial);

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
    final height = MediaQuery.of(context).size.height;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final distance = (height / 3) / devicePixelRatio;

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    return Scaffold(
      backgroundColor: splashColor,
      body: Stack(
        children: [
          buildWhiteIcon(distance),
          buildBottomWave(width, height),
          buildWhiteAppName(distance),
        ],
      ),
    );
  }

  Center buildWhiteAppName(double distance) {
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
              Assets.images.appName,
              width: 135,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }

  Align buildBottomWave(double width, double height) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FadeTransition(
        opacity: secondAnimationController,
        child: Assets.images.waveBack.image(
          fit: BoxFit.fill,
          width: width,
          height: height * 463 / 812,
        ),
      ),
    );
  }

  Center buildWhiteIcon(double distance) {
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
            child: Assets.images.appWhiteIcon.image(),
          ),
        ),
      ),
    );
  }
}
