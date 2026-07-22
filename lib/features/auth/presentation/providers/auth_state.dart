import 'package:equatable/equatable.dart';

import 'package:neuroup/shared/models/user_profile.dart';

class AuthState extends Equatable {
  const AuthState({this.user, this.isLoading = false, this.error});

  final UserProfile? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    user: clearUser ? null : (user ?? this.user),
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [user, isLoading, error];
}
