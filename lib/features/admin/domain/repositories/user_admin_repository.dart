import 'package:neuroup/shared/models/user_profile.dart';

abstract class UserAdminRepository {
  Stream<List<UserProfile>> watchAllUsers();
  Future<void> updateUserRole(String userId, UserRole role);

  /// [banned] true ise hesap askıya alınır — kullanıcı bir sonraki
  /// authStateChanges/giriş kontrolünde otomatik çıkışa zorlanır (bkz.
  /// AuthRepositoryImpl._mapWithRole). Firebase Auth hesabını gerçekten
  /// silmek istemci SDK'sından yapılamaz (Admin SDK/Cloud Function
  /// gerektirir) — bu yüzden "banla" ile eşdeğer, istemci tarafından
  /// uygulanabilir tek yöntem budur.
  Future<void> setBanned(String userId, bool banned);
}
