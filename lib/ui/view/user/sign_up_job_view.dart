import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/job_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_list_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/sign_up_cubit.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUpJobView extends StatelessWidget {
  const SignUpJobView({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = getArguments(context);
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
        appBar: buildBackAppBar(context),
        body: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.w),
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
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        buildJobInput(context, textController),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(55.h),
                        backgroundColor: primary800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: secondary,
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed: jobGroup != null
                          ? () async => processSignUp(context, user, nickname)
                          : null,
                      child: Text(
                        '가입완료',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
          data,
          (_) => false,
          arguments: {
            'index': 0,
          },
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
      margin: EdgeInsets.only(top: 30.h),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextFormField(
            autofocus: true,
            autofillHints: const ['직업을 선택해주세요'],
            controller: textController,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
              color: blackBold,
            ),
            decoration: InputDecoration(
              labelText: '직업',
              labelStyle: const TextStyle(
                color: Color(0xFF9097A3),
                fontWeight: FontWeight.w500,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryTab, width: 2.w),
              ),
              hintText: '직업을 선택해주세요',
              hintStyle: TextStyle(
                color: const Color(0xFFD0D1D2),
                fontWeight: FontWeight.w500,
                fontSize: 17.sp,
              ),
              contentPadding: EdgeInsets.zero,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: greyTab, width: 2.w),
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
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Icon(
                Icons.close_rounded,
                size: 20.r,
                color: lightGrey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<JobGroup?> getJobResult(BuildContext parentContext) async {
    final bottomMargin = MediaQuery.of(parentContext).viewInsets.bottom + 16.h;

    return showModalBottomSheet<JobGroup?>(
      backgroundColor: Colors.transparent,
      context: parentContext,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            BlocProvider(
              create: (_) => JobListCubit(),
              child: BlocBuilder<JobListCubit, List<JobGroup>>(
                builder: (context, jobs) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.r),
                        topRight: Radius.circular(30.r),
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(
                        left: 24.w,
                        right: 24.w,
                        top: 32.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '직업을 선택해주세요',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              if (jobs.isEmpty) {
                                return SizedBox(
                                  height: 300.h,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return buildJobListView(jobs, bottomMargin);
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

  Widget buildJobListView(List<JobGroup> jobs, double bottomMargin) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 431.h,
      ),
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
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
          ),
          SizedBox(
            height: 24.h,
          ),
        ],
      ),
    );
  }

  void changeText(BuildContext context, TextEditingController textController) {
    textController.text =
        context.read<JobCubit>().getJob()?.name ?? '직업을 선택해주세요';
  }
}
