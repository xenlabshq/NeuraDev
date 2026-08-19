import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';
import 'package:neuroup/shared/models/user_profile.dart';

/// Email + şifre ile giriş use case'i. Repository'den bağımsız
/// iş kuralı: doğrulama + Result dönüşü controller'a bırakılır.
///
/// Clean Architecture: presentation katmanı doğrudan repository'i
/// değil, bu use case'i çağırır. İleride rate limit, analytics event'i
/// gibi ek işler burada genişletilebilir.
class LoginUseCase {
  LoginUseCase(this._repo);

  final AuthRepository _repo;

  /// Repository'ye doğrudan erişim için. Use case'ler normalde iş
  /// kuralı ekler ama test'lerde veya passthrough senaryolarda
  /// repository'ye ihtiyaç olabilir.
  AuthRepository get repo => _repo;

  Future<Result<UserProfile>> call({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return Future.value(
        Err<UserProfile>(
          const ValidationFailure('Geçerli bir e-posta adresi gir.'),
        ),
      );
    }
    if (password.length < 6) {
      return Future.value(
        Err<UserProfile>(
          const ValidationFailure('Şifre en az 6 karakter olmalı.'),
        ),
      );
    }
    return _repo.signInWithEmail(trimmedEmail, password);
  }
}
