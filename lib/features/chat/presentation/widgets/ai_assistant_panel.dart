import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:neuroup/app/router/home_shell.dart' show kBottomBarHeight;

import '../../../../app/theme/colors.dart';

const _aiSuggestions = [
  'Dersler nasıl çalışır?',
  'XP kazanma yolları',
  'Oyunları nasıl oynarım?',
  'Rozetler ne işe yarar?',
];

/// AI Asistan paneli — yerel echo cevaplar (8 hazır intent).
/// Destek paneliyle aynı tasarım dilini paylaşır: tema-aware kartlar,
/// asimetrik balon köşeleri, yuvarlak input pill, gradient avatar.
class AiAssistantPanel extends ConsumerStatefulWidget {
  const AiAssistantPanel({super.key});

  @override
  ConsumerState<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends ConsumerState<AiAssistantPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiMessage> _messages = [
    _AiMessage(
      text:
          'Merhaba! Ben Neuroup AI asistanıyım. Öğrenme, dersler, oyunlar veya hesap ile ilgili sorularına yardımcı olabilirim.',
      isMe: false,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() => _sendText(_input.text);
  void _sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _messages.add(_AiMessage(text: trimmed, isMe: true, createdAt: now));
      _messages.add(_AiMessage(
        text: _generateResponse(trimmed),
        isMe: false,
        createdAt: now.add(const Duration(seconds: 1)),
      ));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('merhaba') || lower.contains('selam')) {
      return 'Merhaba! Sana nasıl yardımcı olabilirim? Dersler, oyunlar veya hesap ayarları hakkında soru sorabilirsin.';
    }
    if (lower.contains('ders') || lower.contains('öğren')) {
      return 'Dersler sekmesine gidip "Python Adaları" haritasını açabilirsin. Her ada bir Python konusu öğretir. Şu an Başlangıç Adası tamamlandı.';
    }
    if (lower.contains('oyun')) {
      return 'Oyunlar sekmesinde Kelime Avı, Quick Math ve Renk Eşleştir var. Hepsini deneyebilirsin!';
    }
    if (lower.contains('seviye') || lower.contains('xp') || lower.contains('level')) {
      return 'XP kazanmak için ders tamamla veya oyun oyna. Her 200 XP\'de level atlıyorsun. Profil\'de ilerlemeni görebilirsin.';
    }
    if (lower.contains('rozet') || lower.contains('badge')) {
      return 'Toplam 8 rozet var. Quiz tamamladıkça ve görevleri yerine getirdikçe kazanırsın. Profil\'den kontrol et!';
    }
    if (lower.contains('profil')) {
      return 'Profil\'de seviye, XP, rozetler ve ayarların var. Avatar çerçeven seviyene göre değişir.';
    }
    if (lower.contains('yardım') || lower.contains('help')) {
      return 'Yardım için:\n• "Dersler nasıl çalışır?"\n• "Oyunları nasıl oynarım?"\n• "Seviye sistemi nedir?"\n• "Nasıl rozet kazanırım?"\n\nBirini seç veya kendi sorunu yaz!';
    }
    return 'İlginç bir soru! Şu an yerel moddayım, bazı sorulara cevap verebilirim. "yardım" yazarak neler sorabileceğini görebilirsin.';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.tokensOf(context);
    final hasUserMessages = _messages.any((m) => m.isMe);

    return Container(
      color: tokens.surface,
      child: Column(
        children: [
          Expanded(
            child: hasUserMessages
                ? _AiConversation(
                    messages: _messages,
                    scroll: _scroll,
                    tokens: tokens,
                  )
                : _AiEmptyState(
                    tokens: tokens,
                    onSuggestion: _sendText,
                  ),
          ),
          // Input bar — kBottomBarHeight kadar yukarı offsetli,
          // böylece floating tab bar onu kapatmaz.
          Padding(
            padding: const EdgeInsets.only(bottom: kBottomBarHeight),
            child: _AiInputBar(
              controller: _input,
              onSend: _send,
              tokens: tokens,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiConversation extends StatelessWidget {
  const _AiConversation({
    required this.messages,
    required this.scroll,
    required this.tokens,
  });

  final List<_AiMessage> messages;
  final ScrollController scroll;
  final NColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: messages.length,
      itemBuilder: (_, i) => _AiBubble(
        text: messages[i].text,
        time: messages[i].createdAt,
        isMe: messages[i].isMe,
        tokens: tokens,
      ),
    );
  }
}

class _AiEmptyState extends StatelessWidget {
  const _AiEmptyState({required this.tokens, required this.onSuggestion});

  final NColorTokens tokens;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Neuroup AI',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aşağıdaki önerilerden birini seç ya da kendi sorunu yaz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _aiSuggestions
                .map(
                  (s) => _SuggestionChip(
                    label: s,
                    onTap: () => onSuggestion(s),
                    tokens: tokens,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.tokens,
  });

  final String label;
  final VoidCallback onTap;
  final NColorTokens tokens;

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
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.info,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.info,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiInputBar extends StatelessWidget {
  const _AiInputBar({
    required this.controller,
    required this.onSend,
    required this.tokens,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final NColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border(
          top: BorderSide(color: tokens.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: tokens.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'AI\'a sor...',
                hintStyle: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: tokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.info,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMessage {
  const _AiMessage({
    required this.text,
    required this.isMe,
    required this.createdAt,
  });
  final String text;
  final bool isMe;
  final DateTime createdAt;
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.tokens,
  });

  final String text;
  final DateTime time;
  final bool isMe;
  final NColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.info : tokens.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(color: tokens.border.withValues(alpha: 0.7)),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : tokens.textPrimary,
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
                color: isMe
                    ? Colors.white.withValues(alpha: 0.75)
                    : tokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
