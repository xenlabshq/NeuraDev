import 'package:neuroup/features/chat/domain/entities/support_chat.dart';
import 'package:neuroup/features/chat/domain/entities/support_message.dart';

abstract class SupportChatRepository {
  Stream<List<SupportChat>> watchChatsForUser(String userId);
  Stream<List<SupportChat>> watchOpenChatsForModerators();
  Stream<List<SupportMessage>> watchMessages(String chatId);
  Future<SupportChat> openOrGetChat({
    required String userId,
    required String userName,
    required String userRole,
  });
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required bool isModerator,
    required String text,
  });
  Future<void> assignModerator(String chatId, String moderatorId);
  Future<void> closeChat(String chatId);
}
