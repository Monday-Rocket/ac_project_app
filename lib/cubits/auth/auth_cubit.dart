import 'dart:async';

import 'package:ac_project_app/provider/auth/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? plan;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.plan,
    this.errorMessage,
  });

  bool get isPro => plan == 'pro';
  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? plan,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      plan: plan ?? this.plan,
      errorMessage: errorMessage,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
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

  Future<void> _loadPlan() async {
    try {
      final plan = await _authRepository.getPlan();
      emit(state.copyWith(plan: plan));
    } catch (_) {
      // 플랜 로드 실패 시 free로 유지
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      await _loadPlan();
    } catch (e) {
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
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
