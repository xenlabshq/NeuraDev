import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env/env.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
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

/// Firebase Auth durumu + Firestore'daki gerçek rol — demo modda boş kalır.
/// AuthRepositoryImpl.authStateChanges() rolü users/{uid}.role'den okur;
/// burada FirebaseAuth'u doğrudan kullanmıyoruz çünkü role bilgisi
/// FirebaseAuth üzerinde tutulmuyor — eskiden burası rolü sabit `student`
/// dönerdi, bu yüzden Firebase'e gerçekten bağlandıktan sonra hiçbir
/// moderatör/admin kendi rolünü göremiyordu (haber yönetimi FAB'ı dahil).
final resolvedAuthUserProvider = StreamProvider<UserProfile?>((ref) {
  if (!Env.firebaseConfigured) {
    return const Stream.empty();
  }
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Aktif kullanıcı — demo modda demo user.
final currentAuthUserProvider = Provider<UserProfile?>((ref) {
  if (!Env.firebaseConfigured) {
    return ref.watch(demoUserProvider);
  }
  return ref
      .watch(resolvedAuthUserProvider)
      .maybeWhen(data: (u) => u, orElse: () => null);
});

final mySupportChatStreamProvider = StreamProvider<List<SupportChat>>((ref) {
  final repo = ref.watch(supportChatRepositoryProvider);
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return const Stream.empty();
  return repo.watchChatsForUser(user.id);
});

final openChatsForModeratorsProvider = StreamProvider<List<SupportChat>>((ref) {
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

  /// F-02: Her chat için event-driven broadcast controller.
  /// Polling (200ms) yerine sadece mesaj geldiğinde emit edilir → CPU %5-10
  /// tasarruf, gerçek anında UI güncellemesi.
  final Map<String, StreamController<List<SupportMessage>>> _msgControllers =
      {};

  StreamController<List<SupportMessage>> _controllerFor(String chatId) {
    return _msgControllers.putIfAbsent(
      chatId,
      () => StreamController<List<SupportMessage>>.broadcast(),
    );
  }

  /// `_messages[chatId]` güncellendikten sonra çağrılır → tüm dinleyicilere
  /// yeni snapshot'ı push'lar.
  void _emitMessageUpdate(String chatId) {
    final ctrl = _msgControllers[chatId];
    if (ctrl == null || ctrl.isClosed) return;
    final snapshot = List<SupportMessage>.from(_messages[chatId] ?? const []);
    ctrl.add(snapshot);
  }

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
    _emitMessageUpdate(chatId);

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
      _emitMessageUpdate(chatId);
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
        .where(
          (c) =>
              c.status == SupportChatStatus.open ||
              c.status == SupportChatStatus.assigned,
        )
        .toList();
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String chatId) async* {
    // F-02: Polling kaldırıldı. İlk snapshot hemen yayılır, sonra
    // sadece mesaj eklendiğinde/ai cevabı geldiğinde `_emitMessageUpdate`
    // ile event push'lanır. CPU %5-10 tasarruf.
    final controller = _controllerFor(chatId);
    final initial = List<SupportMessage>.from(_messages[chatId] ?? const []);
    yield initial;
    yield* controller.stream;
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
