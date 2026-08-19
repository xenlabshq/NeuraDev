import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/widgets/common_widgets.dart';
import 'package:neuroup/features/chat/domain/entities/support_chat.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_controller.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  SupportChat? _openingChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenChat());
  }

  Future<void> _maybeOpenChat() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    if (user.role.isSupportStaff) return;
    final chat = await ref.read(supportChatControllerProvider).openChat(user);
    if (!mounted) return;
    setState(() => _openingChat = chat);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));
    }
    if (user.role.isSupportStaff) {
      return _ModeratorListView();
    }
    return _StudentView(activeChat: _openingChat);
  }
}

class _StudentView extends ConsumerWidget {
  const _StudentView({this.activeChat});
  final SupportChat? activeChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final asyncChats = ref.watch(mySupportChatStreamProvider);
    final activeId = activeChat?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Destek Sohbeti')),
      body: asyncChats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (chats) {
          if (chats.isEmpty && activeChat == null) {
            return const EmptyState(
              icon: Icons.support_agent_rounded,
              title: 'Yardım ister misin?',
              message:
                  'Destek ekibimizle sohbet başlat. Sorularını yanıtlamak için buradayız.',
              actionLabel: 'Yeni Sohbet',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final chat = chats[i];
              return _ChatTile(
                title: 'Destek Ekibi',
                subtitle: chat.lastMessage ?? 'Henüz mesaj yok',
                time: chat.lastMessageAt,
                color: AppColors.success,
                onTap: () => context.push('/chat/${chat.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: activeId == null
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (user == null) return;
                final chat = await ref
                    .read(supportChatControllerProvider)
                    .openChat(user);
                if (context.mounted) context.push('/chat/${chat.id}');
              },
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Yeni Sohbet'),
            )
          : null,
    );
  }
}

class _ModeratorListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChats = ref.watch(openChatsForModeratorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bekleyen Sohbetler')),
      body: asyncChats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_rounded,
              title: 'Sohbet yok',
              message: 'Şu an bekleyen kullanıcı sohbeti yok.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final chat = chats[i];
              return _ChatTile(
                title: chat.userName,
                subtitle: chat.lastMessage ?? 'Yeni sohbet',
                time: chat.lastMessageAt,
                color: _statusColor(chat.status),
                onTap: () => context.push('/chat/${chat.id}'),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(SupportChatStatus s) => switch (s) {
    SupportChatStatus.open => AppColors.warning,
    SupportChatStatus.assigned => AppColors.info,
    SupportChatStatus.closed => AppColors.textTertiary,
  };
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final DateTime? time;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (time != null)
                Text(
                  _formatTime(time!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.Hm().format(dt);
    }
    return DateFormat('d MMM').format(dt);
  }
}
