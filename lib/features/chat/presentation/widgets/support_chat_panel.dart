import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/router/home_shell.dart' show kBottomBarHeight;
import '../../../../shared/models/user_profile.dart';
import '../../domain/entities/support_chat.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_providers.dart';

const _quickMessages = [
  'Yardım istiyorum',
  'Bir sorum var',
  'Hata aldım',
];

/// Destek sohbet listesi — açık sohbetler, hızlı mesaj CTA'ları
/// ve moderatör için bekleyen sohbet listesi.
/// AI paneliyle aynı tasarım dilini paylaşır: tema-aware kartlar,
/// yuvarlak pill butonlar, gradient avatar rozetleri.
class SupportChatPanel extends ConsumerStatefulWidget {
  const SupportChatPanel({super.key});

  @override
  ConsumerState<SupportChatPanel> createState() => _SupportChatPanelState();
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
      return _CenteredMessage(text: 'Giriş yapılmadı');
    }
    if (user.role.isSupportStaff) {
      return const _ModeratorListView();
    }
    return _StudentView(activeChat: _activeChat);
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.tokensOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          style: TextStyle(color: tokens.textPrimary, fontSize: 14),
        ),
      ),
    );
  }
}

class _StudentView extends ConsumerWidget {
  const _StudentView({this.activeChat});
  final SupportChat? activeChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final asyncChats = ref.watch(mySupportChatStreamProvider);
    final tokens = AppColors.tokensOf(context);

    return Container(
      color: tokens.surface,
      child: asyncChats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _CenteredMessage(text: 'Hata: $e'),
        data: (chats) {
          if (chats.isEmpty && activeChat == null) {
            return _EmptySupport(
              onNewChat: () => _createNewChat(context, ref),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              kBottomBarHeight + 24,
            ),
            children: [
              if (chats.isNotEmpty) ...[
                _SectionLabel(label: 'Açık sohbetler', tokens: tokens),
                const SizedBox(height: 12),
                ...chats.map(
                  (chat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SupportTile(
                      title: 'Destek Ekibi',
                      subtitle: chat.lastMessage ?? 'Henüz mesaj yok',
                      time: chat.lastMessageAt,
                      color: AppColors.success,
                      onTap: () => context.push('/support/${chat.id}'),
                      tokens: tokens,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _SectionLabel(label: 'Hızlı başlat', tokens: tokens),
              const SizedBox(height: 12),
              _QuickMessageRow(
                user: user!,
                tokens: tokens,
                onTap: (msg) => _sendQuickMessage(context, ref, user, msg),
              ),
            ],
          );
        },
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
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
    String text,
  ) async {
    final chat = await ref.read(supportChatControllerProvider).openChat(user);
    if (context.mounted) {
      context.push('/support/${chat.id}?initial=$text');
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.tokens});
  final String label;
  final NColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: tokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _QuickMessageRow extends StatelessWidget {
  const _QuickMessageRow({
    required this.user,
    required this.tokens,
    required this.onTap,
  });

  final UserProfile user;
  final NColorTokens tokens;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickMessages
          .map(
            (m) => _QuickMessageChip(
              label: m,
              onTap: () => onTap(m),
            ),
          )
          .toList(),
    );
  }
}

class _QuickMessageChip extends StatelessWidget {
  const _QuickMessageChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySupport extends StatelessWidget {
  const _EmptySupport({required this.onNewChat});
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.tokensOf(context);
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.support_agent_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Yardım ister misin?',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Destek ekibimizle sohbet başlat. Sorularını yanıtlamak için buradayız.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewChat,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Yeni sohbet başlat'),
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
    required this.tokens,
  });
  final String title;
  final String subtitle;
  final DateTime? time;
  final Color color;
  final VoidCallback onTap;
  final NColorTokens tokens;

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
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (time != null)
                Text(
                  _formatTime(time!),
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: tokens.textTertiary,
                size: 18,
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
    final tokens = AppColors.tokensOf(context);
    return Container(
      color: tokens.surface,
      child: asyncChats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _CenteredMessage(text: 'Hata: $e'),
        data: (chats) {
          if (chats.isEmpty) {
            return _CenteredMessage(text: 'Şu an bekleyen sohbet yok.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                tokens: tokens,
              );
            },
          );
        },
      ),
    );
  }
}
