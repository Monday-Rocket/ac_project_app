import 'dart:io';

import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/my_folder/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/my_folder/get_folders_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_list_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/sign_up_cubit.dart';
import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/ui/view/home_view.dart';
import 'package:ac_project_app/ui/view/login_view.dart';
import 'package:ac_project_app/ui/view/my_link_view.dart';
import 'package:ac_project_app/ui/view/sign_up_job_view.dart';
import 'package:ac_project_app/ui/view/sign_up_nickname_view.dart';
import 'package:ac_project_app/ui/view/sign_up_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  static const login = '/login';
  static const signUp = '/signUp';
  static const signUpNickname = '/signUpNickname';
  static const singUpJob = '/signUpJob';

  static const home = '/home';
  static const myLinks = '/myLinks';
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
          builder: (_) => const HomeView(),
        );
      case Routes.myLinks:
        return MultiPlatformPageRoute.create(
          builder: (_) => const MyLinkView(),
          settings: RouteSettings(
            arguments: arguments,
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
          settings: RouteSettings(
            arguments: arguments,
          ),
        );
      case Routes.singUpJob:
        return MultiPlatformPageRoute.create(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => JobCubit(null),
              ),
              BlocProvider(
                create: (_) => JobListCubit(null),
              ),
              BlocProvider(
                create: (_) => SignUpCubit(null),
              ),
            ],
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
