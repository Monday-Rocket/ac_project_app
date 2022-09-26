import 'dart:io';

import 'package:ac_project_app/cubits/google_login_cubit.dart';
import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/cubits/weather_cubit.dart';
import 'package:ac_project_app/ui/page/home/home_view.dart';
import 'package:ac_project_app/ui/page/login/login_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  static const login = '/login';
  static const home = '/home';
}

class Pages {
  static Route<dynamic>? getPages(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        /*
          TODO 다른 로그인 추가 예정
         */
        return MultiPlatformPageRoute.create(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GoogleLoginCubit(null),
              ),
            ],
            child: const LoginView(),
          ),
        );
      case Routes.home:
        return MultiPlatformPageRoute.create(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => WeatherCubit(null),
              ),
              BlocProvider(
                create: (_) => UrlDataCubit([]),
              ),
            ],
            child: const HomeView(),
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
          fullscreenDialog: fullscreenDialog!);
    } else if (Platform.isIOS) {
      return CupertinoPageRoute(
          builder: builder,
          settings: settings,
          maintainState: maintainState!,
          fullscreenDialog: fullscreenDialog!);
    } else {
      throw Exception('Platform 미지원');
    }
  }
}
