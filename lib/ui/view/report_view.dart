import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/consts.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/report/report.dart';
import 'package:ac_project_app/models/report/report_result_type.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/provider/api/report/report_api.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  int radioValue = 0;
  List<bool> radioStateList = [true, false, false, false, false, false, false];

  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final reportType = args['type'] as ReportType? ?? ReportType.user;
    final id = args['id'] as int? ?? 0;
    var name = args['name'] as String? ?? '가나다라마바사아자차카타파하';
    if (name.length > 8) {
      name = '${name.substring(0, 8)}...';
    }

    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: SvgPicture.asset(Assets.images.icBack),
            color: grey900,
            padding: EdgeInsets.only(left: 20.w, right: 8.w),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: Text(
            '신고하기',
            style: TextStyle(
              color: grey900,
              fontWeight: FontWeight.bold,
              fontSize: 19.sp,
              height: (22 / 19).h,
              letterSpacing: -0.3.w,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  reportData(context, reportType, id, textController.text),
              style: TextButton.styleFrom(
                disabledForegroundColor: grey400,
                foregroundColor: primary1000,
              ),
              child: Text(
                '완료',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.sp),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExtendedText(
                    "'$name'${reportType.subText}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      height: (28 / 20).h,
                      letterSpacing: -0.2.w,
                      color: grey900,
                    ),
                    maxLines: 1,
                    overflowWidget: TextOverflowWidget(
                      position: TextOverflowPosition.middle,
                      child: Text(
                        '...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                          height: (28 / 20).h,
                          letterSpacing: -0.2.w,
                          color: grey900,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '이유를 선택해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      height: (28 / 20).h,
                      letterSpacing: -0.2.w,
                      color: grey900,
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Text(
                    '신고 누적 횟수가 3회 이상인 사용자는 서비스 이용이 정지되며,\n허위신고일 경우, 신고자의 서비스 활동이 제한될 수 있습니다.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: (18 / 12).h,
                      color: greyText,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 22.h, bottom: 15.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildOptionItem(0, '홍보/영리목적'),
                            SizedBox(height: 8.h),
                            buildOptionItem(2, '음란/청소년 유해'),
                            SizedBox(height: 8.h),
                            buildOptionItem(4, '도배/스팸'),
                            SizedBox(height: 8.h),
                            buildOptionItem(6, '기타'),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildOptionItem(1, '불법정보'),
                              SizedBox(height: 8.h),
                              buildOptionItem(3, '욕설/비방/차별/혐오'),
                              SizedBox(height: 8.h),
                              buildOptionItem(5, '개인정보노출/거래'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12.r)),
                      color: grey100,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Container(
                        height: 98.h,
                        margin: EdgeInsets.only(bottom: 14.h),
                        child: Stack(
                          children: [
                            TextField(
                              controller: textController,
                              enabled: radioValue == 6,
                              style: TextStyle(
                                fontSize: 14.sp,
                                height: (16.7 / 14).h,
                                color: grey600,
                              ),
                              cursorColor: primary600,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              maxLength: 500,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                  left: 16.w,
                                  top: 16.h,
                                  right: 14.w,
                                  bottom: 24.h,
                                ),
                                hintText: '기타 사유를 입력해주세요.',
                                hintStyle: TextStyle(
                                  color: grey400,
                                  fontSize: 14.sp,
                                ),
                                counterText: '',
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 14.w),
                                child: Text(
                                  '${textController.text.length}/500',
                                  style: TextStyle(
                                    color: grey400,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.sp,
                                    letterSpacing: -0.3.w,
                                    height: (16.7 / 14).h,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void reportData(
    BuildContext context,
    ReportType targetType,
    int id,
    String text,
  ) =>
      getIt<ReportApi>().report(
        Report(
          targetType: targetType.name,
          targetId: id,
          reasonType: reportReasons[radioValue],
          otherReason: text,
        ),
      )
          .then((type) {
        if (type == ReportResultType.success) {
          Navigator.pop(context);
          Future.delayed(
            const Duration(milliseconds: 300),
            () => showBottomToast(
              context: context,
              '신고가 접수되었어요!',
              subMsg: '신고에 대한 검토는 최대 24시간안에 진행될 예정이예요',
            ),
          );
        } else if (type == ReportResultType.duplicated) {
          showPopUp(
            title: '이미 신고한 게시물이에요',
            content: '신고는 한 게시물 당 한 번만 할 수 있어요',
            parentContext: context,
            callback: () => Navigator.pop(context),
            icon: true,
          );
        } else {
          showError(context);
        }
      });

  Widget buildOptionItem(int index, String text) {
    final selected = radioValue == index;
    return GestureDetector(
      onTap: () {
        if (radioValue != index) {
          setState(() {
            radioValue = index;
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 7.h, bottom: 7.h, right: 7.w),
            child: Builder(
              builder: (_) {
                if (selected) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 18.w,
                    height: 18.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary700,
                    ),
                    child: Center(
                      child: Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                } else {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 18.w,
                    height: 18.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: grey100,
                    ),
                  );
                }
              },
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: grey700,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
