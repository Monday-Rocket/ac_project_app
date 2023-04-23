import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/ui/view/profile/profile_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../widget_tap_helper.dart';

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

  testWidgets('프로필 닉네임이 불러와지는 지 테스트', (tester) async {
    await tester.pumpWidget(testWidget);

    const nickname = '오키';
    final actual = find.text(nickname);

    expect(actual, findsWidgets);
  });

  testWidgets('4번 프로필을 선택했을 때 화면이 바뀌는 지 테스트', (tester) async {
    await tester.pumpWidget(testWidget);

    // 4번 이미지 버튼 tap
    const selectIndex = 4;
    const key = Key('select:$selectIndex');
    GestureDetectorButton(key)
        .onTap!
        .call(); // 동작 안 함 -> await tester.tap(found, warnIfMissed: false);
    await tester.pump(); // 안 기다려주면 변경된 UI 감지를 못함

    // 선택된 이미지 위젯 찾기
    const selectedImageKey = Key('selectedImage');
    final selectedWidget = find.byKey(selectedImageKey);
    final actualImage = (selectedWidget.evaluate().first.widget as Image).image;

    // 설정하려고 했던 이미지 가져오기
    const targetImagePath =
        'assets/images/profile/img_0${selectIndex+1}_on.png';
    final matcherImage = Image.asset(targetImagePath).image;

    // 같은 이미지인지 확인하기
    expect(actualImage, matcherImage);
  });
}
