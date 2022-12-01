import 'dart:async';

import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class EmailLoginView extends StatefulWidget {
  const EmailLoginView({super.key});

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      retrieveDynamicLinkAndSignIn(fromColdState: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('이메일 로그인')
          ],
        ),
      ),
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        Log.d('resumed');
        unawaited(retrieveDynamicLinkAndSignIn(fromColdState: false));
        break;
      case AppLifecycleState.paused:
        Log.d('paused');
        break;
      case AppLifecycleState.inactive:
        Log.d('inactive');
        break;
      case AppLifecycleState.detached:
        Log.d('detached');
        break;
    }
  }

  Future<bool> retrieveDynamicLinkAndSignIn({
    required bool fromColdState,
  }) async {
    PendingDynamicLinkData? dynamicLinkData;
    Uri? deepLink;

    if (fromColdState) {
      dynamicLinkData = await FirebaseDynamicLinks.instance.getInitialLink();
      if (dynamicLinkData != null) {
        deepLink = dynamicLinkData.link;
      }
    } else {
      dynamicLinkData = await FirebaseDynamicLinks.instance.onLink.first;
      deepLink = dynamicLinkData.link;
    }

    if (deepLink == null) {
      return false;
    }

    final validLink =
        FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString());

    if (validLink) {
      final continueUrl = deepLink.queryParameters['continueUrl'] ?? '';
      final email = Uri.parse(continueUrl).queryParameters['email'] ?? '';
      _handleLink(email, deepLink.toString());
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleLink(String email, String link) {
    Email.login(email, link).then((isSuccess) async {
      if (isSuccess) {
        final user = await UserApi().postUsers();

        user.when(
          success: (data) {
            Navigator.pushReplacementNamed(
              context,
              Routes.home,
              arguments: {'index': 0},
            );
          },
          error: (msg) {
            Log.e('login fail');
          },
        );
      } else {
        Log.e('login fail');
      }
    });
  }
}
