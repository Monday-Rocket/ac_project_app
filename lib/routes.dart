import 'dart:io';

import 'package:ac_project_app/cubits/JobCubit.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/nickname_cubit.dart';
import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/ui/page/home_view.dart';
import 'package:ac_project_app/ui/page/login_view.dart';
import 'package:ac_project_app/ui/page/sign_up_job_view.dart';
import 'package:ac_project_app/ui/page/sign_up_nickname_view.dart';
import 'package:ac_project_app/ui/page/sign_up_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  static const login = '/login';
  static const home = '/home';
  static const signUp = '/signUp';
  static const signUpNickname = '/signUpNickname';
  static const singUpJob = '/signUpJob';
}

class Pages {
  static Route<dynamic>? getPages(RouteSettings settings) {
    final arguments = settings.arguments;
    switch (settings.name) {
      case Routes.login:
        /*
          TODO 다른 로그인 추가 예정
         */
        return MultiPlatformPageRoute.create(
          builder: (_) => BlocProvider(
            create: (_) => LoginCubit(null),
            child: const LoginView(),
          ),
        );
      case Routes.home:
        return MultiPlatformPageRoute.create(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => UrlDataCubit([]),
              ),
            ],
            child: const HomeView(),
          ),
        );
      case Routes.signUp:
        return MultiPlatformPageRoute.create(
          builder: (_) => const SignUpView(),
          settings: RouteSettings(
            arguments: arguments,
          ),
        );
      case Routes.signUpNickname:
        return MultiPlatformPageRoute.create(
          builder: (_) => BlocProvider(
            create: (_) => NicknameCubit(null),
            child: const SignUpNicknameView(),
          ),
        );
      case Routes.singUpJob:
        return MultiPlatformPageRoute.create(
          builder: (_) => BlocProvider(
            create: (_) => JobCubit(null),
            child: const SignUpJobView(),
          ),
          settings: RouteSettings(
            arguments: arguments,
          ),
        );
      default:
        return null;
    }
  }
}

class MultiPlatformPageRoute {
  static PageRoute<dynamic> create({
    required Widget Function(BuildContext) builder,
    RouteSettings? settings,
    bool? maintainState = true,
    bool? fullscreenDialog = true,
  }) {
    if (Platform.isAndroid) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
        maintainState: maintainState!,
        fullscreenDialog: fullscreenDialog!,
      );
    } else if (Platform.isIOS) {
      return CupertinoPageRoute(
        builder: builder,
        settings: settings,
        maintainState: maintainState!,
        fullscreenDialog: fullscreenDialog!,
      );
    } else {
      throw Exception('Platform 미지원');
    }
  }
}
