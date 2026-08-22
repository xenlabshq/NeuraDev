import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/chat/data/repositories/support_chat_repository_impl.dart';
import 'package:neuroup/features/chat/domain/entities/support_chat.dart';
import 'package:neuroup/features/chat/domain/repositories/support_chat_repository.dart';

void main() {
  late SupportChatRepository repo;
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = SupportChatRepositoryImpl(db);
  });

  // Regresyon: bu sorgu MUTLAKA sunucu tarafında `where('userId', ...)`
  // ile filtrelenmeli — filtresiz bir orderBy + istemci tarafı filtre
  // (haberlerdeki desenin buraya kopyalanmış hâli) gerçek Firestore'da
  // firestore.rules'un "sadece kendi sohbetini görebilirsin" kuralını
  // sağladığını KANITLAYAMADIĞI için normal bir kullanıcı için HER ZAMAN
  // permission-denied ile sonuçlanıyordu (bkz. support_chat_repository_impl.dart
  // yorumu). `FakeFirebaseFirestore` güvenlik kurallarını hiç
  // uygulamadığı için bu regresyon testlerde asla görünmüyordu — sadece
  // gerçek bir kullanıcı hesabıyla gerçek Firestore'a karşı test edilince
  // ortaya çıktı. Bu test yine de doğru sorgu SONUCUNU doğruluyor
  // (userId filtresinin doğru çalıştığını).
  test("watchChatsForUser only returns that user's chats", () async {
    await repo.openOrGetChat(
      userId: 'u1',
      userName: 'Ali',
      userRole: 'student',
    );
    await repo.openOrGetChat(
      userId: 'u2',
      userName: 'Veli',
      userRole: 'student',
    );

    final chats = await repo.watchChatsForUser('u1').first;
    expect(chats, hasLength(1));
    expect(chats.single.userId, 'u1');
  });

  test(
    'watchOpenChatsForModerators excludes closed chats',
    () async {
      final chat = await repo.openOrGetChat(
        userId: 'u1',
        userName: 'Ali',
        userRole: 'student',
      );
      await repo.openOrGetChat(
        userId: 'u2',
        userName: 'Veli',
        userRole: 'student',
      );
      await repo.closeChat(chat.id);

      final open = await repo.watchOpenChatsForModerators().first;
      expect(open, hasLength(1));
      expect(open.single.userId, 'u2');
    },
  );

  test(
    'openOrGetChat reuses the existing non-closed chat for a user',
    () async {
      final first = await repo.openOrGetChat(
        userId: 'u1',
        userName: 'Ali',
        userRole: 'student',
      );
      final second = await repo.openOrGetChat(
        userId: 'u1',
        userName: 'Ali',
        userRole: 'student',
      );
      expect(second.id, first.id);
    },
  );

  test(
    'openOrGetChat opens a new chat once the previous one is closed',
    () async {
      final first = await repo.openOrGetChat(
        userId: 'u1',
        userName: 'Ali',
        userRole: 'student',
      );
      await repo.closeChat(first.id);
      final second = await repo.openOrGetChat(
        userId: 'u1',
        userName: 'Ali',
        userRole: 'student',
      );
      expect(second.id, isNot(first.id));
      expect(second.status, SupportChatStatus.open);
    },
  );
}
