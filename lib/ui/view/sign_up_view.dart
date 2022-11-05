import 'package:flutter/material.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {

    final token = ModalRoute.of(context)!.settings.arguments as String? ?? 'null';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(Icons.abc),
        ),
      ),

      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Text(""),
            TextField(

            )
          ],
        ),
      ),
    );



  }
}
