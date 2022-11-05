import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/job_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_list_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/sign_up_cubit.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpJobView extends StatefulWidget {
  const SignUpJobView({super.key});

  @override
  State<SignUpJobView> createState() => _SignUpJobViewState();
}

class _SignUpJobViewState extends State<SignUpJobView> {
  final textHint = '직업을 선택해주세요';
  late TextEditingController _textController;
  late Future<List<JobGroup>> futureJobs;

  @override
  void initState() {
    _textController = TextEditingController(text: textHint);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      futureJobs = context.read<JobListCubit>().getJobList();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final arg =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final nickname = arg['nickname'] as String?;
    final user = arg['user'] as User?;

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
                    '$nickname님의\n직업을 선택해주세요',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  buildJobInput(),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: primary800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: context.watch<JobCubit>().state != null
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
        Navigator.pushNamed(
          context,
          Routes.home,
        );
      },
      error: Log.e,
    );
  }

  Widget buildJobInput() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 24),
      child: GestureDetector(
        child: TextFormField(
          controller: _textController,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: primary800),
            ),
            suffix: IconButton(
              iconSize: 24,
              onPressed: () {
                context.read<JobCubit>().updateJob(null);
                changeText();
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          readOnly: true,
          onTap: () async {
            final result = await getJobResult();

            if (!mounted) return;
            context.read<JobCubit>().updateJob(result);
            changeText();
          },
        ),
      ),
    );
  }

  Future<JobGroup?> getJobResult() async {
    final jobs = await futureJobs;
    return showModalBottomSheet<JobGroup?>(
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return DecoratedBox(
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
                        buildJobListView(jobs),
                      ],
                    ),
                  ),
                );
              },
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
          Flex(
            direction: Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
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
            ],
          ),
          const SizedBox(
            height: 24,
          )
        ],
      ),
    );
  }

  void changeText() {
    _textController.text =
        context.read<JobCubit>().getJob()?.name ?? '직업을 선택해주세요';
  }
}
