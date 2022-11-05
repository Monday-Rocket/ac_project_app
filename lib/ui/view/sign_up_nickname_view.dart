import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_cubit.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpNicknameView extends StatefulWidget {
  const SignUpNicknameView({super.key});

  @override
  State<SignUpNicknameView> createState() => _SignUpNicknameViewState();
}

class _SignUpNicknameViewState extends State<SignUpNicknameView> {
  final RegExp _regKr = RegExp(r'^[가-힣0-9a-zA-Z]{2,8}$', unicode: true);
  final _formKey = GlobalKey<FormState>();
  var _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    BlocProvider.of<NicknameCubit>(context).getNickname();
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as User?;

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
                  buildNicknameField(context),
                ],
              ),
              buildNextButton(user),
            ],
          ),
        ),
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

  Widget buildNextButton(User? user) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(55),
        backgroundColor: _isButtonEnabled ? primary800 : secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _isButtonEnabled
          ? () {
              Navigator.pushNamed(
                context,
                Routes.singUpJob,
                arguments: {
                  'nickname': context.read<NicknameCubit>().getNickname(),
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

  Widget buildNicknameField(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Form(
        key: _formKey,
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
            suffixIcon: _isButtonEnabled
                ? const Icon(
                    Icons.check,
                    color: primary800,
                  )
                : null,
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return '닉네임을 아직 입력하지 않으셨어요';
            } else if (!_regKr.hasMatch(value)) {
              return '닉네임은 한글, 영어, 숫자 2~8글자 입니다.';
            }

            return null;
          },
          onSaved: (String? value) {
            context.read<NicknameCubit>().updateName(value);
          },
          onChanged: (String? value) {
            if (_formKey.currentState != null) {
              if (!_formKey.currentState!.validate()) {
                setState(() {
                  _isButtonEnabled = false;
                });
                return;
              }
              _formKey.currentState!.save();
              setState(() {
                _isButtonEnabled = true;
              });
            }
          },
        ),
      ),
    );
  }
}
