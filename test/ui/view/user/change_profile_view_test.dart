import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/ui/view/profile/profile_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ink_well_button.dart';


void main() {
  final testWidget = MaterialApp(
    home: ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (_, __) {
        return ProfileSelector(
          profile: Profile(
            nickname: '오키',
            profileImage: '02',
          ),
        );
      },
    ),
  );

  testWidgets('프로필 이미지가 불러와지는 지 테스트', (tester) async {
    await tester.pumpWidget(testWidget);
    const imagePath = 'assets/images/profile/img_02_on.png';

    final actual = find.image(Image.asset(imagePath).image);

    expect(actual, findsWidgets);
  });

  testWidgets('프로필 텍스트가 불러와지는 지 테스트', (tester) async {
    await tester.pumpWidget(testWidget);
    const nickname = '오키';

    final actual = find.text(nickname);

    expect(actual, findsWidgets);
  });

  testWidgets('4번 프로필을 선택했을 때 화면이 바뀌는 지 테스트', (tester) async {
    await tester.pumpWidget(testWidget, const Duration(seconds: 3));
    const selectIndex = 4;
    const key = Key('select:$selectIndex');

    GestureDetectorButton(key).onTap!.call(); // 동작 안 함 -> await tester.tap(found, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));  // 안 기다려주면 변경된 UI 감지를 못함

    const selectedImageKey = Key('selectedImage');
    final selectedWidget = find.byKey(selectedImageKey);

    const targetImagePath = 'assets/images/profile/img_05_on.png';
    final actualImage = (selectedWidget.evaluate().first.widget as Image).image;
    final matcherImage = Image.asset(targetImagePath).image;

    expect(actualImage, matcherImage);
  });
}
