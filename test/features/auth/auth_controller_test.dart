import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';
import 'package:neuroup/features/auth/presentation/providers/auth_providers.dart';
import 'package:neuroup/shared/models/user_profile.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
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
