import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/models/user_profile.dart';
import '../../domain/entities/support_chat.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_providers.dart';

const _quickMessages = [
  'Yardım istiyorum',
  'Bir sorum var',
  'Hata aldım',
];

/// Destek sohbet listesi — açık sohbetler ve "yeni sohbet" CTA.
class SupportChatPanel extends ConsumerStatefulWidget {
  const SupportChatPanel({super.key});

  @override
  ConsumerState<SupportChatPanel> createState() =>
      _SupportChatPanelState();
}

class _SupportChatPanelState extends ConsumerState<SupportChatPanel> {
  SupportChat? _activeChat;

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
    setState(() => _activeChat = chat);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Giriş yapılmadı',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (user.role.isSupportStaff) {
      return const _ModeratorListView();
    }
    return _StudentView(activeChat: _activeChat);
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

    return Stack(
      children: [
        asyncChats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e',
              style: const TextStyle(color: Colors.white))),
          data: (chats) {
            if (chats.isEmpty && activeChat == null) {
              return _EmptySupport(
                onNewChat: () => _createNewChat(context, ref),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final chat = chats[i];
                return _SupportTile(
                  title: 'Destek Ekibi',
                  subtitle: chat.lastMessage ?? 'Henüz mesaj yok',
                  time: chat.lastMessageAt,
                  color: AppColors.success,
                  onTap: () => context.push('/support/${chat.id}'),
                );
              },
            );
          },
        ),
        // Quick message chips (üst kısımda)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickMessages.map((m) {
              return _quickMessageChip(
                label: m,
                onTap: () => _sendQuickMessage(context, ref, user!, m),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _quickMessageChip({required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewChat(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    final chat = await ref.read(supportChatControllerProvider).openChat(user);
    if (context.mounted) context.push('/support/${chat.id}');
  }

  Future<void> _sendQuickMessage(
      BuildContext context, WidgetRef ref, UserProfile user, String text) async {
    final chat = await ref.read(supportChatControllerProvider).openChat(user);
    if (context.mounted) {
      context.push('/support/${chat.id}?initial=$text');
    }
  }
}

class _EmptySupport extends StatelessWidget {
  const _EmptySupport({required this.onNewChat});
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.support_agent_rounded,
                size: 44,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yardım ister misin?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Destek ekibimizle sohbet başlat. Sorularını yanıtlamak için buradayız.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFD9D2EC),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Açık kart zemini — koyu temada yazılar net okunsun.
            color: const Color(0xFF2A2440),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.support_agent_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD9D2EC),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (time != null)
                Text(
                  _formatTime(time!),
                  style: const TextStyle(
                    color: Color(0xFFB8AED1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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

class _ModeratorListView extends ConsumerWidget {
  const _ModeratorListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChats = ref.watch(openChatsForModeratorsProvider);
    return asyncChats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Hata: $e', style: const TextStyle(color: Colors.white)),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Şu an bekleyen sohbet yok.',
                style: TextStyle(
                  color: Color(0xFFD9D2EC),
                  fontSize: 15,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final chat = chats[i];
            return _SupportTile(
              title: chat.userName,
              subtitle: chat.lastMessage ?? 'Yeni sohbet',
              time: chat.lastMessageAt,
              color: AppColors.info,
              onTap: () => context.push('/support/${chat.id}'),
            );
          },
        );
      },
    );
  }
}