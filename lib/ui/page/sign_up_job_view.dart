import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/JobCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart' as logger;

class SignUpJobView extends StatefulWidget {
  const SignUpJobView({super.key});

  @override
  State<SignUpJobView> createState() => _SignUpJobViewState();
}

class _SignUpJobViewState extends State<SignUpJobView> {
  final textHint = '직업을 선택해주세요';
  late TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController(text: textHint);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments as String? ?? 'null';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.black,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$arg님의\n직업을 선택해주세요',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  JobInput(),
                ],
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )),
                  onPressed: context.watch<JobCubit>().getJob() != null
                      ? () {
                          logger.Logger().i(
                              '닉네임 : $arg \n직업 : ${BlocProvider.of<JobCubit>(context).getJob()}');
                        }
                      : null,
                  child: const Text(
                    '가입완료',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textWidthBasis: TextWidthBasis.parent,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget JobInput() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 24),
      child: GestureDetector(
        child: TextFormField(
          controller: _textController,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: buttonColor),
              ),
              suffix: IconButton(
                iconSize: 24,
                onPressed: () {
                  context.read<JobCubit>().updateJob(null);
                  changeText();
                },
                icon: const Icon(Icons.close_rounded),
              )),
          readOnly: true,
          onTap: () async {
            final result = await showModalBottomSheet(
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 600,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 24, right: 24, top: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textHint,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        JobList(),
                      ],
                    ),
                  ),
                );
              },
            ) as String?;

            context.read<JobCubit>().updateJob(result);

            changeText();
          },
        ),
      ),
    );
  }

  Widget JobList() {
    final jobs = <String>[
      '개발자',
      '디자이너',
      '기획자',
      '농부',
      '미용사',
      '요리사',
      '서비스직',
      '의사',
      '학생',
      '교사',
      '자영업자',
      '법조인'
    ];

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        shrinkWrap: true,
        itemCount: jobs.length,
        itemBuilder: (BuildContext context, int index) {
          return TextButton(
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
            onPressed: () {
              Navigator.pop(context, jobs[index]);
            },
            child: Text(
              '${jobs[index]}',
              style: const TextStyle(
                color: Colors.black,
              ),
              textAlign: TextAlign.start,
            ),
          );
        },
      ),
    );
  }

  void changeText() {
    _textController.text = context.read<JobCubit>().getJob() ?? '직업을 선택해주세요';
  }
}
