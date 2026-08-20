import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';

/// Kullanıcı rolü `users/{uid}` Firestore dokümanında tutulur —
/// Firebase Auth'un kendisi rol bilgisi taşımaz. Yeni kayıtlar HER ZAMAN
/// `student` rolüyle oluşturulur; moderatör/admin rolü sadece mevcut bir
/// admin tarafından (bu repo dışında, örn. admin panelinden) atanabilir.
/// Bu, Firestore Security Rules ile sunucu tarafında da zorunlu kılınır
/// (bkz. firestore.rules) — client tarafındaki bu kısıtlama tek başına
/// güvenlik sağlamaz, sadece rules ile tutarlılığı korur.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Stream<UserProfile?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((u) async {
      if (u == null) return null;
      return _mapWithRole(u);
    });
  }

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
      return Success(await _mapWithRole(user));
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
      // Sadece ayrıcalıksız hesap türlerine (öğrenci/öğretmen/veli) izin
      // ver — moderatör/admin self-servis atanamaz, sadece mevcut bir
      // admin panelden verebilir. Firestore rules bunu sunucu tarafında
      // da zorunlu kılıyor (bkz. firestore.rules), bu istemci tarafındaki
      // kontrol tek başına güvenlik sağlamaz.
      final safeRole = role.isSupportStaff ? UserRole.student : role;
      await _users.doc(user.uid).set({
        'email': email,
        'displayName': displayName,
        'role': safeRole.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final profile = _map(user).copyWith(role: safeRole);
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
    if (u == null) return const Success(null);
    return Success(await _mapWithRole(u));
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

  Future<UserProfile> _mapWithRole(User u) async {
    var role = UserRole.student;
    try {
      final doc = await _users.doc(u.uid).get();
      final raw = doc.data()?['role'] as String?;
      if (raw != null) {
        role = UserRole.values.firstWhere(
          (r) => r.name == raw,
          orElse: () => UserRole.student,
        );
      }
    } catch (e, st) {
      LoggerService.error('rol okunamadı, student varsayıldı', e, st);
    }
    return _map(u).copyWith(role: role);
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
