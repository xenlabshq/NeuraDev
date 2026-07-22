import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/core/utils/result.dart';
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

  @override
  Stream<List<SupportChat>> watchChatsForUser(String userId) {
    return _chats
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SupportChat.fromDoc).toList());
  }

  @override
  Stream<List<SupportChat>> watchOpenChatsForModerators() {
    return _chats
        .where('status', whereIn: [
      SupportChatStatus.open.name,
      SupportChatStatus.assigned.name,
    ]).orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(SupportChat.fromDoc).toList());
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
    final existing = await _chats
        .where('userId', isEqualTo: userId)
        .where('status', isNotEqualTo: SupportChatStatus.closed.name)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return SupportChat.fromDoc(existing.docs.first);
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
            ? (chatRef.id.isEmpty
                ? SupportChatStatus.assigned.name
                : SupportChatStatus.assigned.name)
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

extension on Object {
  // ignore: unused_element
  Result<void> okOrThrow(Object e) => Err(failureFromException(e));
}
