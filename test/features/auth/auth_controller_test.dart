import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';
import 'package:neuroup/features/auth/domain/usecases/login_usecase.dart';
import 'package:neuroup/features/auth/presentation/providers/auth_providers.dart';
import 'package:neuroup/shared/models/user_profile.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Test helper: doğrulama yapmadan doğrudan repo'yu çağıran use case.
/// Böylece controller test'leri validation mantığından bağımsız çalışır.
class _PassthroughLogin extends LoginUseCase {
  _PassthroughLogin(super.repo);
  @override
  Future<Result<UserProfile>> call({
    required String email,
    required String password,
  }) => repo.signInWithEmail(email, password);
}

void main() {
  late _MockAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        // LoginUseCase validasyonu repository'yi bypass eder;
        // test'lerde mock repo'ya doğrudan ulaşmak için use case'i
        // de passthrough'a override ediyoruz.
        loginUseCaseProvider.overrideWithValue(_PassthroughLogin(repo)),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthController', () {
    test('signInWithEmail updates state with user on success', () async {
      const user = UserProfile(
        id: 'u1',
        email: 'a@b.com',
        displayName: 'A',
        role: UserRole.student,
      );
      when(
        () => repo.signInWithEmail('a@b.com', 'pw'),
      ).thenAnswer((_) async => const Success(user));

      await container
          .read(authStateProvider.notifier)
          .signInWithEmail('a@b.com', 'pw');

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(user));
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('signInWithEmail exposes failure message', () async {
      when(
        () => repo.signInWithEmail(any(), any()),
      ).thenAnswer((_) async => const Err(AuthFailure('Şifre hatalı')));

      await container
          .read(authStateProvider.notifier)
          .signInWithEmail('x', 'y');

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, 'Şifre hatalı');
    });

    test('signOut resets state', () async {
      when(() => repo.signOut()).thenAnswer((_) async {});

      await container.read(authStateProvider.notifier).signOut();

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('signInWithGoogle updates state with user on success', () async {
      const user = UserProfile(
        id: 'g1',
        email: 'g@gmail.com',
        displayName: 'G',
        role: UserRole.student,
      );
      when(
        () => repo.signInWithGoogle(),
      ).thenAnswer((_) async => const Success(user));

      await container.read(authStateProvider.notifier).signInWithGoogle();

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(user));
    });

    test('signInWithGoogle exposes failure message on cancel', () async {
      when(() => repo.signInWithGoogle()).thenAnswer(
        (_) async => const Err(AuthFailure('Google girişi iptal edildi')),
      );

      await container.read(authStateProvider.notifier).signInWithGoogle();

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, 'Google girişi iptal edildi');
    });

    test('sendPasswordResetEmail delegates to the repository', () async {
      when(
        () => repo.sendPasswordResetEmail('a@b.com'),
      ).thenAnswer((_) async => const Success(null));

      final result = await container
          .read(authStateProvider.notifier)
          .sendPasswordResetEmail('a@b.com');

      expect(result.isSuccess, isTrue);
      verify(() => repo.sendPasswordResetEmail('a@b.com')).called(1);
    });
  });

  group('Result', () {
    test('success/failure helpers', () {
      const ok = Success<int>(42);
      const err = Err<int>(UnknownFailure('x'));
      expect(ok.isSuccess, isTrue);
      expect(err.isFailure, isTrue);
      expect(ok.valueOrNull, 42);
      expect(err.failureOrNull, isA<UnknownFailure>());
    });
  });
}
