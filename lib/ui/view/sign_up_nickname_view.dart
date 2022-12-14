// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_cubit.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

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
          return BlocBuilder<ButtonStateCubit, ButtonState>(
            builder: (context, state) {
              return KeyboardDismissOnTap(
                child: KeyboardVisibilityBuilder(
                  builder: (context, visible) {
                    final keyboardHeight =
                        MediaQuery.of(context).viewInsets.bottom;
                    return Scaffold(
                      resizeToAvoidBottomInset: false,
                      appBar: buildBackAppBar(context),
                      body: buildBody(context, state, keyboardHeight),
                      bottomSheet: buildBottomSheetButton(
                        context: context,
                        text: '확인',
                        keyboardVisible: visible,
                        onPressed: state == ButtonState.enabled
                            ? () => Navigator.pushNamed(
                                  context,
                                  Routes.singUpJob,
                                  arguments: {
                                    'nickname': nickname,
                                    'user': user,
                                  },
                                )
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildBody(
    BuildContext context,
    ButtonState state,
    double keyboardHeight,
  ) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTitleText(),
            Stack(
              alignment: Alignment.centerRight,
              children: [
                buildNicknameField(context, state),
                if (state == ButtonState.enabled)
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 40,
                      right: 8,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: primaryTab,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            SizedBox(height: keyboardHeight),
          ],
        ),
      ),
    );
  }

  Widget buildTitleText() {
    return const Text(
      '안녕하세요\n프로필을 만들어볼까요?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildNicknameField(BuildContext context, ButtonState state) {
    final formKey = context.read<NicknameCubit>().formKey;
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: blackBold,
          ),
          decoration: const InputDecoration(
            labelText: '닉네임',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF9097A3),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primary800, width: 2),
            ),
            hintText: '사용하실 닉네임을 입력해주세요',
            hintStyle: TextStyle(
              color: Color(0xFFD0D1D2),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            errorStyle: TextStyle(
              color: redError,
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: redError, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: greyTab, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
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
            if (value?.isEmpty ?? true) {
              context.read<ButtonStateCubit>().disable();
            }
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
