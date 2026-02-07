import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/local/offline_migration_service.dart';
import 'package:ac_project_app/provider/manager/app_pause_manager.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AutoLoginCubit extends Cubit<LoginUserState> {
  AutoLoginCubit() : super(LoginInitialState());

  final appPauseManager = getIt<AppPauseManager>();

  Future<void> userCheck() async {
    Log.i('[AutoLogin] userCheck() 호출됨');
    final pause = await appPauseManager.getPause();
    Log.i('[AutoLogin] pause: $pause');

    if (pause) {
      await _showInspectionMessage();
    } else {
      _userCheck();
    }
  }

  Future<void> _showInspectionMessage() async {
    final title = await appPauseManager.getTitle();
    final description = await appPauseManager.getDescription();
    final timeText = await appPauseManager.getTimeText();
    emit(InspectionState(title, description, timeText));
  }

  void _userCheck() {
    final user = FirebaseAuth.instance.currentUser;
    Log.i('[AutoLogin] Firebase user: ${user?.uid ?? "null"}');

    if (user != null) {
      Log.i('[AutoLogin] postUsers() 호출 중...');
      getIt<UserApi>().postUsers().then((result) {
        result.when(
          success: (data) {
            Log.i('[AutoLogin] postUsers() 성공 - is_new: ${data.is_new}');
            if (data.is_new ?? false) {
              Log.i('[AutoLogin] 새 사용자 - 마이그레이션 스킵');
              emit(LoginInitialState());
            } else {
              // 오프라인 모드: 서버 데이터 마이그레이션 실행
              Log.i('[AutoLogin] 기존 사용자 - 마이그레이션 시작');
              _runMigrationIfNeeded().then((_) {
                emit(LoginLoadedState(data));
              });
            }
          },
          error: (msg) {
            Log.e('[AutoLogin] postUsers() 실패: $msg');
            emit(LoginInitialState());
          },
        );
      });
    } else {
      Log.i('[AutoLogin] Firebase user가 null - 로그인 필요');
    }
  }

  Future<void> _runMigrationIfNeeded() async {
    try {
      final migrationService = getIt<OfflineMigrationService>();
      final result = await migrationService.migrateToLocal();

      if (result.isSuccess) {
        Log.i('Migration completed: ${result.foldersCount} folders, ${result.linksCount} links');
        if (result.logFilePath != null) {
          Log.i('Migration log file: ${result.logFilePath}');
        }
      } else if (result.isAlreadyCompleted) {
        Log.i('Migration already completed');
      } else if (result.isError) {
        Log.e('Migration error: ${result.errorMessage}');
      }
    } catch (e) {
      Log.e('Migration exception: $e');
    }
  }

  void closeApp() {
    appPauseManager.closeApp();
  }
}
