import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/report/report.dart';
import 'package:ac_project_app/models/report/report_result_type.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/provider/api/report/report_api.dart';
import 'package:ac_project_app/ui/widget/dialog.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  int radioValue = 0;
  List<bool> radioStateList = [true, false, false, false, false, false, false];
  List<String> reportTypeList = [
    'COMMERCIAL',
    'ILLEGAL',
    'OBSCENE',
    'SLANDER',
    'SPAM',
    'PERSONAL_INFO',
    'OTHER'
  ];

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

    final targetType = reportType == ReportType.user ? 'USER' : 'LINK';
    final subText = reportType == ReportType.user ? '을 신고하는' : ' 게시글을 신고하는';

    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: SvgPicture.asset('assets/images/ic_back.svg'),
            color: grey900,
            padding: const EdgeInsets.only(left: 20, right: 8),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            '신고하기',
            style: TextStyle(
              color: grey900,
              fontWeight: FontWeight.bold,
              fontSize: 19,
              height: 22 / 19,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => reportData(context, targetType, id, textController.text),
              style: TextButton.styleFrom(
                disabledForegroundColor: grey400,
                foregroundColor: primary1000,
              ),
              child: const Text(
                '완료',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExtendedText(
                    "'$name'$subText",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      height: 28 / 20,
                      letterSpacing: -0.2,
                      color: grey900,
                    ),
                    maxLines: 1,
                    overflowWidget: const TextOverflowWidget(
                      position: TextOverflowPosition.middle,
                      child: Text(
                        '...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          height: 28 / 20,
                          letterSpacing: -0.2,
                          color: grey900,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    '이유를 선택해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      height: 28 / 20,
                      letterSpacing: -0.2,
                      color: grey900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    '허위신고일 경우, 신고자의 서비스 활동이 제한될 수 있습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      color: greyText,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 22, bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildOptionItem(0, '홍보/영리목적'),
                            const SizedBox(height: 8),
                            buildOptionItem(2, '음란/청소년 유해'),
                            const SizedBox(height: 8),
                            buildOptionItem(4, '도배/스팸'),
                            const SizedBox(height: 8),
                            buildOptionItem(6, '기타'),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildOptionItem(1, '불법정보'),
                              const SizedBox(height: 8),
                              buildOptionItem(3, '욕설/비방/차별/혐오'),
                              const SizedBox(height: 8),
                              buildOptionItem(5, '개인정보노출/거래'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: grey100,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Container(
                        height: 98,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Stack(
                          children: [
                            TextField(
                              controller: textController,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 16.7 / 14,
                                color: grey600,
                              ),
                              cursorColor: primary600,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                  left: 16,
                                  top: 16,
                                  right: 14,
                                  bottom: 24,
                                ),
                                hintText: '기타 사유를 입력해주세요.',
                                hintStyle: TextStyle(
                                  color: grey400,
                                  fontSize: 14,
                                ),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Text(
                                  '${textController.text.length}/500',
                                  style: const TextStyle(
                                    color: grey400,
                                    fontSize: 14,
                                    letterSpacing: -0.3,
                                    height: 16.7 / 14,
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

  void reportData(BuildContext context, String targetType, int id, String text) =>
      ReportApi()
          .report(
        Report(
          targetType: targetType,
          targetId: id,
          reasonType: reportTypeList[radioValue],
          otherReason: text,
        ),
      )
          .then((type) {
        if (type == ReportResultType.success) {
          Navigator.pop(context);
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
            padding: const EdgeInsets.only(top: 7, bottom: 7, right: 7),
            child: Builder(
              builder: (_) {
                if (selected) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary700,
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
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
                    width: 18,
                    height: 18,
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
            style: const TextStyle(
              color: grey700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
