import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_cubit.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpNicknameView extends StatelessWidget {
  const SignUpNicknameView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as User?;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NicknameCubit(),
        ),
        BlocProvider(
          create: (_) => ButtonStateCubit(),
        ),
      ],
      child: BlocBuilder<NicknameCubit, String?>(
        builder: (context, nickname) {
          final cubit = context.read<ButtonStateCubit>();
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
                        buildTitleText(),
                        buildNicknameField(context, cubit),
                      ],
                    ),
                    buildNextButton(context, user, nickname, cubit),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTitleText() {
    return const Text(
      '안녕하세요\n프로필을 만들어볼까요?',
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildNextButton(
    BuildContext context,
    User? user,
    String? nickname, ButtonStateCubit cubit,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(55),
        backgroundColor:
        cubit.state == ButtonState.enabled ? primary800 : secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: cubit.state == ButtonState.enabled
          ? () {
              Navigator.pushNamed(
                context,
                Routes.singUpJob,
                arguments: {
                  'nickname': nickname,
                  'user': user,
                },
              );
            }
          : null,
      child: const Text(
        '확인',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
        textWidthBasis: TextWidthBasis.parent,
      ),
    );
  }

  Widget buildNicknameField(BuildContext context, ButtonStateCubit cubit) {
    final formKey = context.read<NicknameCubit>().formKey;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: '닉네임',
            labelStyle: const TextStyle(
              color: Colors.grey,
            ),
            hintText: '사용하실 닉네임을 입력해주세요',
            hoverColor: primary800,
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: primary800),
            ),
            errorStyle: const TextStyle(
              color: redError,
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: redError),
            ),
            suffixIcon: cubit.state == ButtonState.enabled
                ? const Icon(
                    Icons.check,
                    color: primary800,
                  )
                : null,
          ),
          validator: (value) {
            final regKr = RegExp(r'^[가-힣0-9a-zA-Z]{2,8}$', unicode: true);
            if (value!.isEmpty) {
              return '닉네임을 아직 입력하지 않으셨어요';
            } else if (!regKr.hasMatch(value)) {
              return '닉네임은 한글, 영어, 숫자 2~8글자 입니다.';
            }

            return null;
          },
          onSaved: (String? value) {
            context.read<NicknameCubit>().updateName(value);
          },
          onChanged: (String? value) {
            if (formKey.currentState != null) {
              if (!formKey.currentState!.validate()) {
                context.read<ButtonStateCubit>().disable();
                return;
              }
              formKey.currentState!.save();
              context.read<ButtonStateCubit>().enable();
            }
          },
        ),
      ),
    );
  }
}
