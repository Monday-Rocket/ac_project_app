import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        UserApi().postUsers().then((result) {
          result.when(
            success: (data) {
              if (data.is_new ?? false) {
                Navigator.pushReplacementNamed(context, Routes.login);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  Routes.home,
                  arguments: {
                    'index': 0,
                  },
                );
              }
            },
            error: (_) => unawaited(
              Navigator.pushReplacementNamed(context, Routes.login),
            ),
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
    final height = MediaQuery.of(context).size.height;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final distance = (height / 3) / devicePixelRatio;
    print(devicePixelRatio);

    //Setting SysemUIOverlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);

    return Scaffold(
      backgroundColor: splashColor,
      body: Stack(
        children: [
          buildWhiteIcon(distance),
          buildBottomWave(width),
          buildWhiteAppName(distance),
        ],
      ),
    );
  }

  Center buildWhiteAppName(double distance) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 80),
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
          fit: BoxFit.cover,
          width: width,
        ),
      ),
    );
  }

  Center buildWhiteIcon(double distance) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 80),
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
