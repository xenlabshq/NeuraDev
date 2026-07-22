import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env/env.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../features/learning/presentation/providers/learning_providers.dart';
import '../../../../shared/models/user_profile.dart';
import '../../data/repositories/support_chat_repository_impl.dart';
import '../../domain/entities/support_chat.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/repositories/support_chat_repository.dart';

/// Demo modda sahte kullanıcı döner — XP/level gerçek LearningProgressNotifier'dan,
/// streak yine oradan çekilir. 750'de takılı kalmaz.
final demoUserProvider = Provider<UserProfile>((ref) {
  final progress = ref.watch(userProgressProvider);
  final totalXp = progress.totalXp;
  final level = totalXp <= 0 ? 1 : (totalXp ~/ 100) + 1;
  return UserProfile(
    id: 'demo_user',
    email: 'demo@neuroup.app',
    displayName: 'Demo Kullanıcı',
    role: UserRole.student,
    level: level,
    xp: totalXp,
    streakDays: progress.streak,
  );
});

final supportChatRepositoryProvider = Provider<SupportChatRepository>(
  (ref) {
    if (!Env.firebaseConfigured) {
      // Demo modda in-memory repository kullan
      return _InMemorySupportChatRepository();
    }
    return SupportChatRepositoryImpl(ref.watch(firestoreProvider));
  },
);

/// Firebase Auth state — demo modda sabit demo user döner.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  if (!Env.firebaseConfigured) {
    return const Stream.empty();
  }
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Aktif kullanıcı — demo modda demo user.
final currentAuthUserProvider = Provider<UserProfile?>((ref) {
  if (!Env.firebaseConfigured) {
    return ref.watch(demoUserProvider);
  }
  final asyncUser = ref.watch(firebaseAuthStateProvider);
  return asyncUser.maybeWhen(
    data: (u) => u == null
        ? null
        : UserProfile(
            id: u.uid,
            email: u.email ?? '',
            displayName: u.displayName ??
                (u.email?.split('@').first ?? 'Kullanıcı'),
            role: UserRole.student,
            avatarUrl: u.photoURL,
          ),
    orElse: () => null,
  );
});

final mySupportChatStreamProvider = StreamProvider<List<SupportChat>>((ref) {
  final repo = ref.watch(supportChatRepositoryProvider);
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return const Stream.empty();
  return repo.watchChatsForUser(user.id);
});

final openChatsForModeratorsProvider =
    StreamProvider<List<SupportChat>>((ref) {
  final repo = ref.watch(supportChatRepositoryProvider);
  return repo.watchOpenChatsForModerators();
});

final chatMessagesStreamProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, chatId) {
  final repo = ref.watch(supportChatRepositoryProvider);
  return repo.watchMessages(chatId);
});

/// In-memory sohbet repository — demo mod için.
/// Firestore olmadan çalışır, gerçek backend bağlandığında otomatik değişir.
class _InMemorySupportChatRepository implements SupportChatRepository {
  final Map<String, List<SupportMessage>> _messages = {};
  final Map<String, SupportChat> _chats = {};
  String? _currentChatId;

  @override
  Future<SupportChat> openOrGetChat({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    if (_currentChatId != null && _chats.containsKey(_currentChatId)) {
      return _chats[_currentChatId]!;
    }
    final id = 'demo_chat_${DateTime.now().millisecondsSinceEpoch}';
    final chat = SupportChat(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      status: SupportChatStatus.open,
      createdAt: DateTime.now(),
    );
    _chats[id] = chat;
    _currentChatId = id;

    // Hoş geldin mesajı
    _messages[id] = [
      SupportMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        chatId: id,
        senderId: 'system',
        senderName: 'Neuroup Destek',
        isModerator: true,
        text:
            'Merhaba! Demo modunda olduğun için gerçek moderatörler burada değil. '
            'Yine de mesaj gönderebilirsin — AI asistanı cevap verecek.',
        createdAt: DateTime.now(),
      ),
    ];
    return chat;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required bool isModerator,
    required String text,
  }) async {
    final msg = SupportMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      isModerator: isModerator,
      text: text,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(chatId, () => []).add(msg);

    // Chat'i güncelle
    final chat = _chats[chatId];
    if (chat != null) {
      _chats[chatId] = chat.copyWith(
        lastMessage: text,
        lastMessageAt: msg.createdAt,
        lastMessageSenderId: senderId,
      );
    }

    // AI cevabı (1 saniye gecikme)
    if (!isModerator) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final aiReply = _generateAiReply(text);
      final aiMsg = SupportMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: 'ai_moderator',
        senderName: 'AI Asistan',
        isModerator: true,
        text: aiReply,
        createdAt: DateTime.now(),
      );
      _messages[chatId]!.add(aiMsg);
      _chats[chatId] = _chats[chatId]!.copyWith(
        lastMessage: aiReply,
        lastMessageAt: aiMsg.createdAt,
        lastMessageSenderId: 'ai_moderator',
      );
    }
  }

  String _generateAiReply(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('merhaba') || lower.contains('selam')) {
      return 'Merhaba! Nasıl yardımcı olabilirim? Dersler, oyunlar veya hesap '
          'hakkında sorularını yanıtlayabilirim.';
    }
    if (lower.contains('ders') || lower.contains('öğren')) {
      return 'Dersler sekmesine gidip öğrenme haritasını açabilirsin. '
          'Her node bir dersi temsil eder, sırayla tamamla!';
    }
    if (lower.contains('oyun') || lower.contains('kelime')) {
      return 'Oyunlar sekmesinden "Kelime Avı" oyununa ulaşabilirsin. '
          'Karışık harfleri sıraya koyarak puan kazanırsın!';
    }
    if (lower.contains('seviye') || lower.contains('xp')) {
      return 'XP kazanarak seviye atliyorsun. Bronz → Gümüş → Altın → Elmas → Usta '
          'şeklinde 5 tier var. Profilinden ilerlemeyi görebilirsin.';
    }
    if (lower.contains('rozet') || lower.contains('badge')) {
      return 'Quiz tamamladıkça ve görevleri yerine getirdikçe rozetler kazanırsın. '
          'Toplam 8 farklı rozet var. Profil sekmesinden kontrol et!';
    }
    if (lower.contains('profil')) {
      return 'Profil sekmesinde seviye, XP, rozetler ve ayarlarını görebilirsin. '
          'Avatarının etrafındaki çerçeve seviyene göre değişir.';
    }
    if (lower.contains('yardım') || lower.contains('help')) {
      return 'Sık sorulan sorular:\n'
          '• Ders nasıl tamamlanır?\n'
          '• Oyunlarda nasıl puan kazanırım?\n'
          '• Profil çerçevem neden değişmedi?\n\n'
          'Bir tanesini seç veya kendi sorunu yaz!';
    }
    if (lower.contains('teşekkür') || lower.contains('sağol')) {
      return 'Rica ederim! Başka sorun olursa çekinme. 🎓';
    }
    return 'Anladım. Demo modunda olduğun için yanıtlarım sınırlı. '
        'Gerçek moderatörlerimiz Firebase bağlantısı sonrası devreye girecek. '
        'Bu arada Profil, Dersler veya Oyunlar sekmelerine göz atabilirsin!';
  }

  @override
  Stream<List<SupportChat>> watchChatsForUser(String userId) async* {
    yield _chats.values.where((c) => c.userId == userId).toList();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    yield _chats.values.where((c) => c.userId == userId).toList();
  }

  @override
  Stream<List<SupportChat>> watchOpenChatsForModerators() async* {
    yield _chats.values
        .where((c) =>
            c.status == SupportChatStatus.open ||
            c.status == SupportChatStatus.assigned)
        .toList();
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String chatId) async* {
    final list = List<SupportMessage>.from(_messages[chatId] ?? const []);
    yield list;
    // Auto-update when new message arrives
    await for (final int _ in Stream<int>.periodic(
      const Duration(milliseconds: 200),
      (x) => x,
    )) {
      final current = _messages[chatId] ?? const [];
      if (current.length != list.length) {
        list
          ..clear()
          ..addAll(current);
        yield List<SupportMessage>.from(current);
      }
    }
  }

  @override
  Future<void> assignModerator(String chatId, String moderatorId) async {
    _chats[chatId] = _chats[chatId]!.copyWith(
      moderatorId: moderatorId,
      status: SupportChatStatus.assigned,
    );
  }

  @override
  Future<void> closeChat(String chatId) async {
    _chats[chatId] = _chats[chatId]!.copyWith(
      status: SupportChatStatus.closed,
    );
  }
}
