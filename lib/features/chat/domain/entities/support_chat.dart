import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SupportChatStatus { open, assigned, closed }

class SupportChat extends Equatable {
  factory SupportChat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SupportChat(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Kullanıcı',
      userRole: data['userRole'] as String? ?? 'student',
      status: SupportChatStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SupportChatStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      moderatorId: data['moderatorId'] as String?,
    );
  }
  const SupportChat({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.status,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.moderatorId,
  });

  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final SupportChatStatus status;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final String? moderatorId;

  bool get hasUnread =>
      lastMessageSenderId != userId && status == SupportChatStatus.open;

  SupportChat copyWith({
    SupportChatStatus? status,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    String? moderatorId,
  }) => SupportChat(
    id: id,
    userId: userId,
    userName: userName,
    userRole: userRole,
    status: status ?? this.status,
    createdAt: createdAt,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    moderatorId: moderatorId ?? this.moderatorId,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userRole': userRole,
    'status': status.name,
    'createdAt': createdAt,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt,
    'lastMessageSenderId': lastMessageSenderId,
    'moderatorId': moderatorId,
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userRole,
    status,
    createdAt,
    lastMessage,
    lastMessageAt,
    lastMessageSenderId,
    moderatorId,
  ];
}
