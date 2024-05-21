import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/login/auto_login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/tutorial_provider.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
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

  final autoLoginCubit = getIt<AutoLoginCubit>();

  @override
  void initState() {
    autoLoginCubit.userCheck();
    setAnimationController();
    loginAfterAnimation();
    super.initState();
  }

  void loginAfterAnimation() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      checkTutorial2(
        onMoveToTutorialView: moveToTutorialView,
        onMoveToNextView: moveToNextView,
      );
    });
  }

  void moveToNextView() {
    final state = autoLoginCubit.state;
    if (state is LoginInitialState) {
      moveToLoginView();
    } else if (state is InspectionState) {
      showPausePopup(
        title: state.title,
        description: state.description,
        timeText: state.timeText,
        parentContext: context,
        callback: () {
          Navigator.pop(context);
          autoLoginCubit.closeApp();
        },
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        Routes.home,
        arguments: {
          'index': 0,
        },
      );
    }
  }

  void moveToLoginView() =>
      Navigator.pushReplacementNamed(context, Routes.login);

  void moveToTutorialView() =>
      Navigator.pushReplacementNamed(context, Routes.tutorial);

  void setAnimationController() {
    setFirstAnimationController();
    setSecondAnimationController();
    firstAnimationController.forward();
    forwardSecondAnimationAfter300mills();
    secondAnimationController.forward();
  }

  void forwardSecondAnimationAfter300mills() {
    Timer(
      const Duration(milliseconds: 300),
      () => secondAnimationController.forward(),
    );
  }

  void setSecondAnimationController() {
    secondAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    );
  }

  void setFirstAnimationController() {
    firstAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    );
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
