import 'dart:async';

import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/auth/auth_repository.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? plan;
  final DateTime? planExpiresAt;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.plan,
    this.planExpiresAt,
    this.errorMessage,
  });

  /// 만료까지 고려한 Pro 여부.
  bool get isPro {
    if (plan != 'pro') return false;
    if (planExpiresAt == null) return true;
    return planExpiresAt!.isAfter(DateTime.now());
  }

  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? plan,
    DateTime? planExpiresAt,
    String? errorMessage,
    bool clearExpiresAt = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      plan: plan ?? this.plan,
      planExpiresAt:
          clearExpiresAt ? null : (planExpiresAt ?? this.planExpiresAt),
      errorMessage: errorMessage,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final SyncRepository? _syncRepository;
  StreamSubscription<AuthState>? _authSubscription;

  static const _kCachedPlan = 'lp_cached_plan';

  AuthCubit({
    required AuthRepository authRepository,
    SyncRepository? syncRepository,
  })  : _authRepository = authRepository,
        _syncRepository =
            syncRepository ?? (getIt.isRegistered<SyncRepository>() ? getIt<SyncRepository>() : null),
        super(const AuthState()) {
    _init();
  }

  void _init() {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      _loadPlan();
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }

    _authRepository.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
        _loadPlan();
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    });
  }

  /// Plan 조회 + 캐시 비교 후 free↔pro 전환 트리거. 앱 시작/포그라운드 복귀/로그인 성공 시 호출.
  Future<void> refreshPlan() => _loadPlan();

  Future<void> _loadPlan() async {
    try {
      final info = await _authRepository.getPlanInfo();
      final effective = info.effectivePlan;
      final previous = await SharedPrefHelper.getValueFromKey<String>(
        _kCachedPlan,
        defaultValue: '',
      );

      emit(state.copyWith(
        plan: effective,
        planExpiresAt: info.expiresAt,
        clearExpiresAt: info.expiresAt == null,
      ));

      await SharedPrefHelper.saveKeyValue(_kCachedPlan, effective);

      // 전환 감지
      if (previous.isEmpty || previous == effective) return;
      if (_syncRepository == null) return;

      if (previous == 'free' && effective == 'pro') {
        Log.i('Plan transition: free → pro. Triggering initial backup.');
        unawaited(_syncRepository.backupToRemote());
      } else if (previous == 'pro' && effective == 'free') {
        Log.i('Plan transition: pro → free. Restore + purge.');
        unawaited(() async {
          try {
            await _syncRepository.restoreFromRemote();
          } catch (e) {
            Log.e('restoreFromRemote failed: $e');
          }
          try {
            await _syncRepository.purgeRemote();
          } catch (e) {
            Log.e('purgeRemote failed: $e');
          }
        }());
      }
    } catch (_) {
      // 플랜 로드 실패 시 상태 유지
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      Log.i('signInWithGoogle: starting');
      final user = await _authRepository.signInWithGoogle();
      Log.i('signInWithGoogle: success user=${user.id}');
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      await _loadPlan();
    } catch (e, st) {
      Log.e('signInWithGoogle: FAILED $e\n$st');
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await _authRepository.signInWithApple();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      await _loadPlan();
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    await SharedPrefHelper.saveKeyValue(_kCachedPlan, '');
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
