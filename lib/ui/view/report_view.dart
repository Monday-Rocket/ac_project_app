import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final reportType = args['type'] as ReportType;
    final id = args['id'] as int;
    final name = args['name'] as String;

    final text = reportType == ReportType.user ? "'$name'을 신고하는\n이유를 선택해주세요" : "'$name' 게시글을 신고하는\n이유를 선택해주세요";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new),
          color: grey900,
          padding: const EdgeInsets.only(left: 24, right: 8),
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
            onPressed: () {},
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
                Text(
                  text,
                  style: const TextStyle(
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
                          buildOptionItem(1, '음란/청소년 유해'),
                          const SizedBox(height: 8),
                          buildOptionItem(2, '도배/스팸'),
                          const SizedBox(height: 8),
                          buildOptionItem(3, '기타'),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildOptionItem(4, '불법정보'),
                            const SizedBox(height: 8),
                            buildOptionItem(5, '욕설/비방/차별/혐오'),
                            const SizedBox(height: 8),
                            buildOptionItem(6, '개인정보노출/거래'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    color: grey100,
                  ),
                  constraints: const BoxConstraints(
                    minHeight: 90,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: textController,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 16.7 / 14,
                        color: grey600,
                      ),
                      cursorColor: primary600,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      autofocus: true,
                      maxLength: 500,
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
                        counterStyle: TextStyle(
                          color: grey400,
                          fontSize: 14,
                          letterSpacing: -0.3,
                          height: 16.7 / 14,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

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
