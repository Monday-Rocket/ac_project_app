import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermPage extends StatefulWidget {


  const TermPage({
    Key? key,
  }) : super(key: key);

  @override
  State<TermPage> createState() => _TermPageState();
}

class _TermPageState extends State<TermPage> {

  @override
  void initState() {
    super.initState();

    if(Platform.isAndroid)
      WebView.platform = AndroidWebView();
    else if (Platform.isIOS)
      WebView.platform = CupertinoWebView();

  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as LinkArguments;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            size: 16,
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF191F28),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              '닫기',
              style: TextStyle(
                fontSize: 16,
                color: grey800,
                fontFamily: R_Font.PRETENDARD,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body:  WebView(
          initialUrl: args.link, //https://www.notion.so/bside/11fa525dedad4aa1b9e34d2988c6fc89
        ),


    );
  }
}
