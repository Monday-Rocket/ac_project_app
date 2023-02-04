import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimationTest(),
    ),
  );
}

class AnimationTest extends StatelessWidget {
  const AnimationTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Lottie.asset(
              'assets/animations/loading.json',
              frameRate: FrameRate(60),
            ),
          ),
        ),
      ),
    );
  }
}
