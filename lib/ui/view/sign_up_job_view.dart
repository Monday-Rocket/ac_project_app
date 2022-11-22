import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/job_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_list_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/sign_up_cubit.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/get_json_argument.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpJobView extends StatelessWidget {
  const SignUpJobView({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = getJsonArgument(context);
    final nickname = arg['nickname'] as String?;
    final user = arg['user'] as User?;
    final textController = TextEditingController();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => JobCubit(),
        ),
        BlocProvider(
          create: (_) => SignUpCubit(),
        ),
      ],
      child: Scaffold(
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
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: BlocBuilder<JobCubit, JobGroup?>(
              builder: (context, jobGroup) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nickname님의\n직업을 선택해주세요',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        buildJobInput(context, textController),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(55),
                        backgroundColor: primary800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: secondary,
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed: jobGroup != null
                          ? () async => processSignUp(context, user, nickname)
                          : null,
                      child: const Text(
                        '가입완료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textWidthBasis: TextWidthBasis.parent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> processSignUp(
    BuildContext context,
    User? user,
    String? nickname,
  ) async {
    final result = await context.read<SignUpCubit>().signUp(
          user: user,
          nickname: nickname,
          job: context.read<JobCubit>().getJob(),
        );
    result.when(
      success: (data) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.home,
          (_) => false,
        );
      },
      error: Log.e,
    );
  }

  Widget buildJobInput(
    BuildContext context,
    TextEditingController textController,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 30),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextFormField(
            autofocus: true,
            autofillHints: const ['직업을 선택해주세요'],
            controller: textController,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: blackBold,
            ),
            decoration: const InputDecoration(
              labelText: '직업',
              labelStyle: TextStyle(
                color: Color(0xFF9097A3),
                fontWeight: FontWeight.w500,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryTab, width: 2),
              ),
              hintText: '직업을 선택해주세요',
              hintStyle: TextStyle(
                color: Color(0xFFD0D1D2),
                fontWeight: FontWeight.w500,
                fontSize: 17,
              ),
              contentPadding: EdgeInsets.zero,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: greyTab, width: 2),
              ),
            ),
            readOnly: true,
            onTap: () async {
              unawaited(
                getJobResult(context).then((result) {
                  context.read<JobCubit>().updateJob(result);
                  changeText(context, textController);
                }),
              );
            },
          ),
          InkWell(
            onTap: () {
              context.read<JobCubit>().updateJob(null);
              changeText(context, textController);
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<JobGroup?> getJobResult(BuildContext context) async {
    return showModalBottomSheet<JobGroup?>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            BlocProvider(
              create: (_) => JobListCubit(),
              child: BlocBuilder<JobListCubit, List<JobGroup>>(
                builder: (context, jobs) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Container(
                      margin:
                          const EdgeInsets.only(left: 24, right: 24, top: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '직업을 선택해주세요',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              if (jobs.isEmpty) {
                                return const SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return buildJobListView(jobs);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildJobListView(List<JobGroup> jobs) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 431,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                    jobs[index].name ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.start,
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 24,
          )
        ],
      ),
    );
  }

  void changeText(BuildContext context, TextEditingController textController) {
    textController.text =
        context.read<JobCubit>().getJob()?.name ?? '직업을 선택해주세요';
  }
}
