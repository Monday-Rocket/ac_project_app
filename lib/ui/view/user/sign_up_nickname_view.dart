// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_check_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/sign_up_cubit.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        BlocProvider(
          create: (_) => NicknameCheckCubit(),
        ),
        BlocProvider(
          create: (_) => SignUpCubit(),
        ),
      ],
      child: BlocBuilder<NicknameCubit, String?>(
        builder: (context, nickname) {
          return BlocBuilder<ButtonStateCubit, ButtonState>(
            builder: (context, state) {
              final formKey = context.read<NicknameCubit>().formKey;
              return KeyboardDismissOnTap(
                child: KeyboardVisibilityBuilder(
                  builder: (context, visible) {
                    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                    return Scaffold(
                      resizeToAvoidBottomInset: false,
                      appBar: buildBackAppBar(context),
                      body: buildBody(context, state, keyboardHeight, formKey),
                      bottomSheet: buildBottomSheetButton(
                        context: context,
                        text: '확인',
                        keyboardVisible: visible,
                        onPressed: state == ButtonState.enabled
                            ? () {
                                context
                                    .read<NicknameCheckCubit>()
                                    .isDuplicated(nickname!)
                                    .then((bool result) {
                                  if (result) {
                                    processSignUp(context, user, nickname);
                                  } else {
                                    formKey.currentState?.validate();
                                  }
                                });
                              }
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
    GlobalKey<FormState> formKey,
  ) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(24.w, 16.w, 24.w, 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTitleText(),
            Stack(
              alignment: Alignment.centerRight,
              children: [
                buildNicknameField(context, state, formKey),
                if (state == ButtonState.enabled)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 40.w,
                      right: 8.w,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: primaryTab,
                      size: 20.w,
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
    return Text(
      '안녕하세요\n프로필을 만들어볼까요?',
      style: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildNicknameField(
    BuildContext context,
    ButtonState state,
    GlobalKey<FormState> formKey,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 30.w),
      child: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            color: blackBold,
          ),
          decoration: InputDecoration(
            labelText: '닉네임',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF9097A3),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primary800, width: 2.w),
            ),
            hintText: '사용하실 닉네임을 입력해주세요',
            hintStyle: TextStyle(
              color: const Color(0xFFD0D1D2),
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
            ),
            errorStyle: const TextStyle(
              color: redError,
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: redError, width: 2.w),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: greyTab, width: 2.w),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          validator: (value) {
            final regKr = RegExp(r'^[가-힣0-9a-zA-Z]{2,8}$', unicode: true);
            if (value!.isEmpty) {
              return '닉네임을 아직 입력하지 않으셨어요';
            } else if (!regKr.hasMatch(value)) {
              return '닉네임은 한글, 영어, 숫자 2~8글자 입니다.';
            } else if (context.read<NicknameCheckCubit>().state == false) {
              context.read<NicknameCheckCubit>().reset();
              return '이미 사용하고 있는 닉네임이예요';
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

  Future<void> processSignUp(
    BuildContext context,
    User? user,
    String? nickname,
  ) async {
    final result = await context.read<SignUpCubit>().signUp(
          user: user,
          nickname: nickname,
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
}
