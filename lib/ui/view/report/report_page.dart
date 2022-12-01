import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';

enum ReportReason {
  PROMOTION_PROFIT,
  ILLEGAL_INFO,
  OBSCENE,
  AVERSION,
  SPAM,
  DEAL,
  ETC
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<String> reason = [
    '홍보/영리목적',
    '불법정보',
    '음란/청소년 유해',
    '욕설/비방/차별/혐오',
    '도배/스팸',
    '개인정보노출/거래',
    '기타',
  ];

  ReportReason repostReason = ReportReason.AVERSION;

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: grey900,
        title: Text('신고하기'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: primary600,
            ),
            onPressed: () {},
            child: Text(
              '완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 26,
            ),
            Text(
              '\'제목\'게시글을 신고하는\n이유를 선택해주세요 ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                fontFamily: 'Pretendard',
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(
              height: 9,
            ),
            Text(
              '허위신고일 경우, 신고자의 서비스 활동이 제한될 수 있습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: greyText,
              ),
            ),
            SizedBox(
              height: 24,
            ),
            GridTile(
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                itemCount: reason.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4,
                ),
                itemBuilder: (ctx, index) {
                  return RadioListTile(
                    activeColor: primary600,
                    dense: true,
                    isThreeLine: false,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reason[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    value: ReportReason.values[index],
                    groupValue: repostReason,
                    onChanged: (value) {
                      setState(() {
                        repostReason = value as ReportReason;
                      });
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: grey100,
              ),
              padding: EdgeInsets.only(bottom: 12),
              child: TextFormField(

                controller: _controller,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                ),
                decoration: InputDecoration(
                  hintText: '기타사유를 입력해주세요.',
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
                minLines: 4,
                maxLength: 300,
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
