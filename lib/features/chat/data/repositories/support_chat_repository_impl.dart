import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/features/chat/domain/entities/support_chat.dart';
import 'package:neuroup/features/chat/domain/entities/support_message.dart';
import 'package:neuroup/features/chat/domain/repositories/support_chat_repository.dart';

class SupportChatRepositoryImpl implements SupportChatRepository {
  SupportChatRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('support_chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  // ÖNEMLİ: burada `orderBy` DEĞİL, `where('userId', ...)` sunucu
  // tarafında filtreleniyor — sıralamayı client-side yapmanın nedeni bir
  // composite index'ten kaçınmak değil, firestore.rules'un `support_chats`
  // için "sadece kendi sohbetini görebilirsin" kuralını doğrulayabilmesi.
  // Firestore, bir `list` sorgusunun güvenlik kuralını sağladığını ancak
  // sorgunun KENDİSİ (where filtresiyle) bunu garanti ediyorsa kanıtlayabilir;
  // filtresiz bir orderBy + sonucu Dart'ta filtrelemek (haberlerde olduğu
  // gibi, ama haberler herkese açık okunduğu için orada sorun yok) burada
  // normal bir kullanıcı için HER ZAMAN "permission-denied" ile
  // sonuçlanırdı — moderatör/admin olmayan biri kendi destek sohbetini
  // bile göremezdi.
  @override
  Stream<List<SupportChat>> watchChatsForUser(String userId) {
    return _chats.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final chats = snap.docs.map(SupportChat.fromDoc).toList();
      chats.sort((a, b) {
        final at = a.lastMessageAt;
        final bt = b.lastMessageAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return chats;
    });
  }

  @override
  Stream<List<SupportChat>> watchOpenChatsForModerators() {
    const openStatuses = {
      SupportChatStatus.open,
      SupportChatStatus.assigned,
    };
    return _chats
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(SupportChat.fromDoc)
              .where((c) => openStatuses.contains(c.status))
              .toList(),
        );
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(SupportMessage.fromDoc).toList());
  }

  @override
  Future<SupportChat> openOrGetChat({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    // Tek eşitlik filtresi (userId) — otomatik indekslenir, composite
    // index gerekmez. `status != closed` filtresi Dart tarafında.
    final existing = await _chats.where('userId', isEqualTo: userId).get();
    final open = existing.docs
        .map(SupportChat.fromDoc)
        .where((c) => c.status != SupportChatStatus.closed);
    if (open.isNotEmpty) {
      return open.first;
    }
    final doc = _chats.doc();
    final chat = SupportChat(
      id: doc.id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      status: SupportChatStatus.open,
      createdAt: DateTime.now(),
    );
    await doc.set(chat.toMap());
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
    final msgRef = _messages(chatId).doc();
    final chatRef = _chats.doc(chatId);
    final msg = SupportMessage(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      isModerator: isModerator,
      text: text,
      createdAt: DateTime.now(),
    );
    await _db.runTransaction((tx) async {
      tx.set(msgRef, msg.toMap());
      tx.update(chatRef, {
        'lastMessage': text,
        'lastMessageAt': msg.createdAt,
        'lastMessageSenderId': senderId,
        'status': isModerator
            ? SupportChatStatus.assigned.name
            : SupportChatStatus.open.name,
      });
    });
    LoggerService.info('message sent: $chatId');
  }

  @override
  Future<void> assignModerator(String chatId, String moderatorId) async {
    await _chats.doc(chatId).update({
      'moderatorId': moderatorId,
      'status': SupportChatStatus.assigned.name,
    });
  }

  @override
  Future<void> closeChat(String chatId) async {
    await _chats.doc(chatId).update({
      'status': SupportChatStatus.closed.name,
    });
  }
}
