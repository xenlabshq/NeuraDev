import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroup/features/auth/data/repositories/auth_repository_impl.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth auth;
  late _MockUser user;
  late FakeFirebaseFirestore db;

  setUp(() {
    auth = _MockFirebaseAuth();
    user = _MockUser();
    db = FakeFirebaseFirestore();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.com');
    when(() => user.displayName).thenReturn('Ali');
    when(() => user.photoURL).thenReturn(null);
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  // Regresyon: admin panelinden banlanan bir kullanıcı bir sonraki
  // authStateChanges/currentUser kontrolünde otomatik çıkışa
  // zorlanmalı — aksi halde "banla" özelliği ismen var ama pratikte
  // hesaba erişimi engellemiyor olurdu.
  test(
    'currentUser() signs out and returns null for a banned account',
    () async {
      await db.collection('users').doc('u1').set({
        'role': 'student',
        'banned': true,
      });
      final repo = AuthRepositoryImpl(auth, db);

      final result = await repo.currentUser();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
      verify(() => auth.signOut()).called(1);
    },
  );

  test(
    'currentUser() returns the profile normally for a non-banned account',
    () async {
      await db.collection('users').doc('u1').set({
        'role': 'student',
        'banned': false,
      });
      final repo = AuthRepositoryImpl(auth, db);

      final result = await repo.currentUser();

      expect(result.valueOrNull?.id, 'u1');
      expect(result.valueOrNull?.banned, isFalse);
      verifyNever(() => auth.signOut());
    },
  );
}
