import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/chat/domain/entities/support_chat.dart';
import 'package:neuroup/features/chat/domain/repositories/support_chat_repository.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart';

class SupportChatController {
  SupportChatController(this._ref);
  final Ref _ref;

  SupportChatRepository get _repo =>
      _ref.read(supportChatRepositoryProvider);

  Future<SupportChat> openChat(UserProfile user) async {
    final chat = await _repo.openOrGetChat(
      userId: user.id,
      userName: user.displayName,
      userRole: user.role.name,
    );
    LoggerService.info('chat opened/retrieved: ${chat.id}');
    return chat;
  }

  Future<void> send({
    required String chatId,
    required UserProfile sender,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _repo.sendMessage(
      chatId: chatId,
      senderId: sender.id,
      senderName: sender.displayName,
      isModerator: sender.role.isSupportStaff,
      text: trimmed,
    );
  }

  Future<void> assignModerator(String chatId, String moderatorId) =>
      _repo.assignModerator(chatId, moderatorId);

  Future<void> close(String chatId) => _repo.closeChat(chatId);
}

final supportChatControllerProvider = Provider<SupportChatController>(
  SupportChatController.new,
);
