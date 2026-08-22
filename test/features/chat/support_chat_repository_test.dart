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

  // Regresyon: gerçek Firestore'da `where()` + farklı alanda `orderBy()`
  // kombinasyonu composite index istiyor ve index yoksa
  // `failed-precondition` hatasıyla akışın tamamı çöküyordu (kullanıcı
  // Destek sekmesini hiç açamıyordu). Çözüm: tek-alanlı orderBy +
  // istemci tarafı filtre — bkz. news_repository_impl.dart'taki aynı
  // desen. FakeFirebaseFirestore composite index gereksinimini simüle
  // etmiyor, bu yüzden bu test doğrudan sorgu SONUCUNU doğruluyor
  // (userId/status filtrelerinin hâlâ doğru çalıştığını).
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
