import 'package:firebase_auth/firebase_auth.dart';

import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<UserProfile?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u == null ? null : _map(u));

  @override
  Future<Result<UserProfile>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Err(AuthFailure('Kullanıcı bulunamadı'));
      }
      return Success(_map(user));
    } on FirebaseAuthException catch (e, st) {
      LoggerService.error('signInWithEmail failed', e, st);
      return Err(AuthFailure(_mapAuthError(e)));
    } catch (e, st) {
      LoggerService.error('signInWithEmail unexpected', e, st);
      return Err(failureFromException(e, st));
    }
  }

  @override
  Future<Result<UserProfile>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Err(AuthFailure('Kayıt oluşturulamadı'));
      }
      await user.updateDisplayName(displayName);
      final profile = _map(user).copyWith(role: role);
      return Success(profile);
    } on FirebaseAuthException catch (e, st) {
      LoggerService.error('registerWithEmail failed', e, st);
      return Err(AuthFailure(_mapAuthError(e)));
    } catch (e, st) {
      LoggerService.error('registerWithEmail unexpected', e, st);
      return Err(failureFromException(e, st));
    }
  }

  @override
  Future<void> signOut() async => _auth.signOut();

  @override
  Future<Result<UserProfile?>> currentUser() async {
    final u = _auth.currentUser;
    return Success(u == null ? null : _map(u));
  }

  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    try {
      await _auth.currentUser?.updateDisplayName(profile.displayName);
      return const Success(null);
    } catch (e, st) {
      return Err(failureFromException(e, st));
    }
  }

  UserProfile _map(User u) => UserProfile(
    id: u.uid,
    email: u.email ?? '',
    displayName: u.displayName ?? (u.email?.split('@').first ?? 'Kullanıcı'),
    role: UserRole.student,
    avatarUrl: u.photoURL,
  );

  String _mapAuthError(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'Geçersiz e-posta adresi',
    'user-disabled' => 'Bu hesap devre dışı',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'E-posta veya şifre hatalı',
    'email-already-in-use' => 'Bu e-posta zaten kullanılıyor',
    'weak-password' => 'Şifre çok zayıf',
    _ => e.message ?? 'Kimlik doğrulama hatası',
  };
}
