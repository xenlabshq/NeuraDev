import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SupportMessage extends Equatable {

  factory SupportMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SupportMessage(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Anonim',
      isModerator: data['isModerator'] as bool? ?? false,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  const SupportMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.isModerator,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final bool isModerator;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'isModerator': isModerator,
        'text': text,
        'createdAt': createdAt,
      };

  @override
  List<Object?> get props =>
      [id, chatId, senderId, senderName, isModerator, text, createdAt];
}
