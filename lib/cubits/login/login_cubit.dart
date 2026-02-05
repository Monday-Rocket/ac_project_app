import 'dart:async';

import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/kakao/kakao.dart';
import 'package:ac_project_app/provider/local/offline_migration_service.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/email_password.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/provider/login/naver_login.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<LoginUserState> {
  LoginCubit() : super(LoginInitialState());

  final UserApi userApi = getIt();

  void initialize() {
    emit(LoginInitialState());
  }

  void loading() {
    emit(LoginLoadingState());
  }

  void showError(String message) {
    Log.e('login fail');
    emit(LoginErrorState(message));
  }

  void showNothing() {
    emit(LoginEmptyState());
  }

  void login(LoginType loginType, {String? email, String? password}) {
    emit(LoginLoadingState());
    switch (loginType) {
      case LoginType.google:
        Google.login().then(sendResult);
        break;
      case LoginType.apple:
        Apple.login().then(sendResult);
        break;
      case LoginType.kakao:
        Kakao.login().then(sendResult);
        break;
      case LoginType.naver:
        Naver.login().then(sendResult);
        break;
      case LoginType.signedLoginTest:
        EmailPassword.signedLogin(email, password).then(sendResult);
        break;
    }
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> sendResult(bool isSuccess) async {
    if (isSuccess) {
      final user = await userApi.postUsers();

      await user.when(
        success: (data) async {
          if (data.is_new ?? false) {
            Log.i('[Login] 새 사용자 - 마이그레이션 스킵');
          } else {
            // 오프라인 모드: 서버 데이터 마이그레이션 실행
            Log.i('[Login] 기존 사용자 - 마이그레이션 시작');
            await _runMigrationIfNeeded();
          }
          emit(LoginLoadedState(data));
        },
        error: (msg) {
          emit(LoginErrorState(msg));
        },
      );
    } else {
      Log.e('login fail');
      emit(LoginErrorState('login fail'));
    }
  }

  Future<void> _runMigrationIfNeeded() async {
    try {
      final migrationService = getIt<OfflineMigrationService>();
      final result = await migrationService.migrateToLocal();

      if (result.isSuccess) {
        Log.i('[Login] Migration completed: ${result.foldersCount} folders, ${result.linksCount} links');
        if (result.logFilePath != null) {
          Log.i('[Login] Migration log file: ${result.logFilePath}');
        }
      } else if (result.isAlreadyCompleted) {
        Log.i('[Login] Migration already completed');
      } else if (result.isError) {
        Log.e('[Login] Migration error: ${result.errorMessage}');
      }
    } catch (e) {
      Log.e('[Login] Migration exception: $e');
    }
  }
}
