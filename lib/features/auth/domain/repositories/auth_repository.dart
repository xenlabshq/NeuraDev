import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/shared/models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> authStateChanges();
  Future<Result<UserProfile>> signInWithEmail(String email, String password);
  Future<Result<UserProfile>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  });
  Future<Result<UserProfile>> signInWithGoogle();
  Future<Result<void>> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<Result<UserProfile?>> currentUser();
  Future<Result<void>> updateProfile(UserProfile profile);
}
