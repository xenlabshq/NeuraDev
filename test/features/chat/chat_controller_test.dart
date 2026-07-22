import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroup/features/chat/domain/entities/support_chat.dart';
import 'package:neuroup/features/chat/domain/entities/support_message.dart';
import 'package:neuroup/features/chat/domain/repositories/support_chat_repository.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_controller.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart';
import 'package:neuroup/shared/models/user_profile.dart';

class _MockRepo extends Mock implements SupportChatRepository {}

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [
        supportChatRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('openChat returns existing chat', () async {
    const user = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      displayName: 'Ali',
      role: UserRole.student,
    );
    final existing = SupportChat(
      id: 'c1',
      userId: 'u1',
      userName: 'Ali',
      userRole: 'student',
      status: SupportChatStatus.open,
      createdAt: _epoch,
    );
    when(() => repo.openOrGetChat(
          userId: any(named: 'userId'),
          userName: any(named: 'userName'),
          userRole: any(named: 'userRole'),
        )).thenAnswer((_) async => existing);

    final result = await container
        .read(supportChatControllerProvider)
        .openChat(user);

    expect(result.id, 'c1');
  });

  test('send trims and skips empty', () async {
    const user = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      displayName: 'Ali',
      role: UserRole.student,
    );
    when(() => repo.sendMessage(
          chatId: any(named: 'chatId'),
          senderId: any(named: 'senderId'),
          senderName: any(named: 'senderName'),
          isModerator: any(named: 'isModerator'),
          text: any(named: 'text'),
        )).thenAnswer((_) async {});

    final ctrl = container.read(supportChatControllerProvider);

    await ctrl.send(chatId: 'c1', sender: user, text: '   ');
    verifyNever(() => repo.sendMessage(
          chatId: any(named: 'chatId'),
          senderId: any(named: 'senderId'),
          senderName: any(named: 'senderName'),
          isModerator: any(named: 'isModerator'),
          text: any(named: 'text'),
        ));

    await ctrl.send(chatId: 'c1', sender: user, text: '  Merhaba  ');
    verify(() => repo.sendMessage(
          chatId: 'c1',
          senderId: 'u1',
          senderName: 'Ali',
          isModerator: false,
          text: 'Merhaba',
        )).called(1);
  });

  test('SupportMessage and SupportChat fromDoc handle nulls', () {
    expect(SupportMessage.fromDoc, isNotNull);
    expect(SupportChat.fromDoc, isNotNull);
  });
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
