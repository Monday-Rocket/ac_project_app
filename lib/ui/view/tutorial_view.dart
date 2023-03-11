import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TutorialView extends StatefulWidget {
  const TutorialView({super.key});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CarouselSlider(
            items: tutorials
                .map(
                  (tutorial) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    tutorial.image,
                    height: (height * 0.6).h,
                    fit: BoxFit.cover,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: tutorials.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _controller.animateToPage(entry.key),
                        child: Container(
                          width: 7.w,
                          height: 7.h,
                          margin: EdgeInsets.symmetric(
                            horizontal: 3.w,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _current == entry.key
                                ? primary700
                                : greyDot,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    tutorial.title,
                    style: TextStyle(
                      fontSize: 26.sp,
                      letterSpacing: -0.2.w,
                      color: blackTutorial,
                    ),
                  ).bold(),
                  SizedBox(height: 10.h),
                  Text(
                    tutorial.subTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: greyTutorial,
                      letterSpacing: -0.3.w,
                      height: 24.h / 14,
                    ),
                  ),
                ],
              ),
            )
                .toList(),
            carouselController: _controller,
            options: CarouselOptions(
              height: (height * 646 / 812 - 10).h,
              viewportFraction: 1,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
          ),
          buildBottomSheetButton(
            context: context,
            text: '시작하기',
            backgroundColor: primary700,
            onPressed: moveToLoginView,
          ),
        ],
      ),
    );
  }

  void moveToLoginView() =>
      Navigator.pushReplacementNamed(context, Routes.login);
}
