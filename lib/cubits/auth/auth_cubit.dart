import 'dart:async';

import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/auth/auth_repository.dart';
import 'package:ac_project_app/provider/shared_pref_provider.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

/// Pro 전환 업로드(§2.1) 진행 단계. UI 로딩 팝업에서 텍스트 분기용.
enum ProBackupPhase {
  /// 업로드 중이 아님.
  idle,

  /// 스냅샷 확보 + 원격 초기화
  preparing,

  /// 폴더 업로드 (parent_id 2차 업데이트 포함)
  uploadingFolders,

  /// 링크 업로드
  uploadingLinks,

  /// 성공 완료 (토스트 후 idle 로 복귀)
  done,

  /// 실패 완료 (토스트 후 idle 로 복귀)
  failed,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? plan;
  final DateTime? planExpiresAt;
  final String? errorMessage;
  final ProBackupPhase backupPhase;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.plan,
    this.planExpiresAt,
    this.errorMessage,
    this.backupPhase = ProBackupPhase.idle,
  });

  /// 업로드 중(로딩 Dialog 노출 대상).
  bool get isBackupInProgress =>
      backupPhase == ProBackupPhase.preparing ||
      backupPhase == ProBackupPhase.uploadingFolders ||
      backupPhase == ProBackupPhase.uploadingLinks;

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
    ProBackupPhase? backupPhase,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      plan: plan ?? this.plan,
      planExpiresAt:
          clearExpiresAt ? null : (planExpiresAt ?? this.planExpiresAt),
      errorMessage: errorMessage,
      backupPhase: backupPhase ?? this.backupPhase,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final SyncRepository? _syncRepository;
  StreamSubscription<AuthState>? _authSubscription;

  static const _kCachedPlan = 'lp_cached_plan';
  static const _kGraceUntil = 'lp_grace_until';
  static const Duration _kGracePeriod = Duration(days: 7);

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

  /// Pro→Free 전환 후 원격 데이터가 보존되는 기한. 도래하면 서버 cron 이 원격을 정리한다.
  /// Pro 상태로 재구독되면 [_kGraceUntil] 은 지워진다.
  Future<DateTime?> getGraceUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGraceUntil);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

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
      if (previous.isEmpty || previous == effective) {
        // 전환 에지 없음 — Pro 상태면 주기 pull 에 편승해 즉시 1회 당겨온다.
        // SYNC_MODEL_V2 §2.2: 앱 콜드 스타트/로그인 성공 시 full pull.
        if (effective == 'pro' && _syncRepository != null) {
          unawaited(_syncRepository.pullFromRemote());
        }
        return;
      }
      if (_syncRepository == null) return;

      if (previous == 'free' && effective == 'pro') {
        // SYNC_MODEL_V2 §2.1: 로컬로 원격 full replace.
        // 재구독이면 이전 Grace period 기록 초기화 (stale 원격은 덮어쓰여 자연히 무효).
        Log.i('Plan transition: free → pro. Initial backup + clear grace.');
        unawaited(_runInitialBackup());
      } else if (previous == 'pro' && effective == 'free') {
        // SYNC_MODEL_V2 §2.3: 원격 → 로컬 full replace + Grace period 7일 기록.
        // purge 는 서버 cron 이 Grace 만료 후 처리하므로 클라이언트에서 호출하지 않는다.
        Log.i('Plan transition: pro → free. Restore + set grace (7d).');
        unawaited(() async {
          try {
            await _syncRepository.restoreFromRemote();
          } catch (e) {
            Log.e('restoreFromRemote failed: $e');
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            final graceUntil = DateTime.now().add(_kGracePeriod);
            await prefs.setString(
              _kGraceUntil,
              graceUntil.toIso8601String(),
            );
            Log.i('Grace period set until $graceUntil');
          } catch (e) {
            Log.e('set grace_until failed: $e');
          }
        }());
      }
    } catch (_) {
      // 플랜 로드 실패 시 상태 유지
    }
  }

  /// free→pro 전환 시 백업 오케스트레이션. UI 로딩 Dialog 는 [AuthState.backupPhase] 를 구독한다.
  Future<void> _runInitialBackup() async {
    if (_syncRepository == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGraceUntil);
    } catch (e) {
      Log.e('clear grace_until failed: $e');
    }

    emit(state.copyWith(backupPhase: ProBackupPhase.preparing));
    try {
      final ok = await _syncRepository.backupToRemote(
        onPhase: (phase, {current, total}) {
          switch (phase) {
            case BackupPhase.preparing:
              emit(state.copyWith(backupPhase: ProBackupPhase.preparing));
            case BackupPhase.uploadingFolders:
              emit(state.copyWith(backupPhase: ProBackupPhase.uploadingFolders));
            case BackupPhase.uploadingLinks:
              emit(state.copyWith(backupPhase: ProBackupPhase.uploadingLinks));
          }
        },
      );
      emit(state.copyWith(
        backupPhase: ok ? ProBackupPhase.done : ProBackupPhase.failed,
      ));
    } catch (e) {
      Log.e('initial backup failed: $e');
      emit(state.copyWith(backupPhase: ProBackupPhase.failed));
    }
    // Dialog 가 phase 전이를 감지한 뒤 idle 로 되돌려 Dialog 를 닫는다.
    // 너무 빨리 idle 로 가면 완료 토스트/애니메이션을 놓칠 수 있어 약간 지연.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(backupPhase: ProBackupPhase.idle));
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
