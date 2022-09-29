import 'package:flutter/cupertino.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {

    final token = ModalRoute.of(context)!.settings.arguments as String? ?? 'null';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Center(
        child: Text(token, style: const TextStyle(color: CupertinoColors.black),),
      ),
    );
  }
}
