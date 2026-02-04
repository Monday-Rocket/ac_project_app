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
    final pause = await appPauseManager.getPause();

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
    if (user != null) {
      getIt<UserApi>().postUsers().then((result) {
        result.when(
          success: (data) {
            if (data.is_new ?? false) {
              emit(LoginInitialState());
            } else {
              // 오프라인 모드: 서버 데이터 마이그레이션 실행
              _runMigrationIfNeeded().then((_) {
                emit(LoginLoadedState(data));
              });
            }
          },
          error: (_) => emit(LoginInitialState()),
        );
      });
    }
  }

  Future<void> _runMigrationIfNeeded() async {
    try {
      final migrationService = getIt<OfflineMigrationService>();
      final result = await migrationService.migrateToLocal();

      if (result.isSuccess) {
        Log.i('Migration completed: ${result.foldersCount} folders, ${result.linksCount} links');
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
