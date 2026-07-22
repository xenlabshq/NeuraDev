import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';
import 'package:neuroup/features/auth/presentation/providers/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(firebaseAuthProvider)),
);

final authStateProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());
  final AuthRepository _repo;

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.signInWithEmail(email, password);
    if (!mounted) return;
    state = result.when(
      success: (user) => state.copyWith(user: user, isLoading: false),
      failure: (f) => state.copyWith(isLoading: false, error: f.message),
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
    );
    if (!mounted) return;
    state = result.when(
      success: (user) => state.copyWith(user: user, isLoading: false),
      failure: (f) => state.copyWith(isLoading: false, error: f.message),
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }
}
