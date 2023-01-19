import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/tutorial/tutorial.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class TutorialView extends StatefulWidget {
  const TutorialView({super.key});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  int _current = 0;
  final CarouselController _controller = CarouselController();
  final List<Tutorial> tutorials = [
    Tutorial(
      'assets/tutorials/tutorial1.png',
      '즉시 저장 가능한 링크',
      '검색하다 발견한 인사이트를\n간편하게 저장해보세요',
    ),
    Tutorial(
      'assets/tutorials/tutorial2.png',
      '폴더링으로 링크분류',
      '링크를 카테고리별로 분류하고\n쉽게 찾아보세요',
    ),
    Tutorial(
      'assets/tutorials/tutorial3.png',
      '보기 쉬운 링크 관리',
      '차곡차곡 정리해둔 내 링크\n언제든지 한 눈에 볼 수 있어요',
    ),
    Tutorial(
      'assets/tutorials/tutorial4.png',
      '노트로 상세한 기억 저장',
      '방금 떠오른 아이디어,\n잊지 않도록 링크 노트에 메모해 보세요',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CarouselSlider(
            items: tutorials
                .map(
                  (tutorial) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        tutorial.image,
                        fit: BoxFit.cover,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: tutorials.asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => _controller.animateToPage(entry.key),
                            child: Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 3,
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
                      const SizedBox(height: 22),
                      Text(
                        tutorial.title,
                        style: const TextStyle(
                          fontSize: 26,
                          letterSpacing: -0.2,
                          color: blackTutorial,
                        ),
                      ).bold(),
                      const SizedBox(height: 10),
                      Text(
                        tutorial.subTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: greyTutorial,
                          letterSpacing: -0.3,
                          height: 24 / 14,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
            carouselController: _controller,
            options: CarouselOptions(
              aspectRatio: 375 / 646,
              viewportFraction: 1,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
          ),
        ],
      ),
      bottomSheet: buildBottomSheetButton(
        context: context,
        text: '시작하기',
        backgroundColor: primary700,
        onPressed: () {},
      ),
    );
  }
}
