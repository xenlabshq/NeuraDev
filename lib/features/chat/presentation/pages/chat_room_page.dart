import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:neuroup/app/router/home_shell.dart' show kBottomBarHeight;

import '../../../../app/theme/colors.dart';
import '../../../../shared/models/user_profile.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_providers.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({required this.channelId, super.key});
  final String channelId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(UserProfile user) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(supportChatControllerProvider)
          .send(
            chatId: widget.channelId,
            sender: user,
            text: text,
          );
      _input.clear();
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.tokensOf(context);
    final user = ref.watch(currentAuthUserProvider);
    final asyncMessages = ref.watch(
      chatMessagesStreamProvider(widget.channelId),
    );

    ref.listen(chatMessagesStreamProvider(widget.channelId), (_, __) {
      _scrollToBottom();
    });

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: user.role.isSupportStaff
                    ? AppColors.success
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                user.role.isSupportStaff
                    ? Icons.support_agent_rounded
                    : Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.role.isSupportStaff ? 'Kullanıcı' : 'Destek Ekibi',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user.role.isSupportStaff ? 'Yanıtlanmadı' : 'Çevrimiçi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: user.role.isSupportStaff
                          ? AppColors.textSecondary
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (user.role.isSupportStaff)
            IconButton(
              tooltip: 'Sohbeti kapat',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => ref
                  .read(supportChatControllerProvider)
                  .close(widget.channelId),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Mesaj listesi — input bar yüksekliği + floating tab bar
          // yüksekliği kadar alt boşluk bırak, son mesajlar gizlenmesin.
          Positioned.fill(
            child: asyncMessages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sohbete hoş geldin!\nMesajını aşağıya yaz.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    120 + kBottomBarHeight,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMe = m.senderId == user.id;
                    return _Bubble(
                      text: m.text,
                      time: m.createdAt,
                      isMe: isMe,
                      isModerator: m.isModerator && !isMe,
                    );
                  },
                );
              },
            ),
          ),
          // Input bar — ekranın altından kBottomBarHeight kadar yukarı
          // sabitlenir, böylece hem klavye açıldığında hem de floating
          // tab bar açıkken input her zaman tıklanabilir/erişilebilir
          // kalır.
          Positioned(
            left: 0,
            right: 0,
            // kBottomBarHeight (floating tab bar) + cihaz gesture/system
            // navigation bar inset'i. Emulator'de bu son değer 0'dır;
            // gerçek cihazda (Pixel/Samsung gesture nav) 24-48 px döner.
            // Hesaba katmadan `Positioned(bottom: 84)` cihazda input'u
            // navigation bar'ın altına sıkıştırıyordu.
            bottom: kBottomBarHeight + MediaQuery.viewPaddingOf(context).bottom,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  border: Border(
                    top: BorderSide(
                      color: tokens.border.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(user),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Mesaj yaz...',
                          hintStyle: TextStyle(
                            color: tokens.textTertiary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: tokens.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : () => _send(user),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.time,
    required this.isMe,
    this.isModerator = false,
  });

  final String text;
  final DateTime time;
  final bool isMe;
  final bool isModerator;

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? AppColors.primary
        : (isModerator
              ? AppColors.success.withValues(alpha: 0.95)
              : Colors.white);
    final fg = isMe
        ? Colors.white
        : (isModerator ? Colors.white : AppColors.textPrimary);
    final border = isMe
        ? null
        : (isModerator
              ? Border.all(
                  color: AppColors.success,
                  width: 1.5,
                )
              : Border.all(color: AppColors.border.withValues(alpha: 0.5)));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: border,
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (isModerator && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'MODERATÖR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(time),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
