import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:neuroup/app/router/home_shell.dart' show kBottomBarHeight;

import '../../../../app/theme/colors.dart';
import '../../../../l10n/gen/app_localizations.dart';

List<String> _aiSuggestions(AppLocalizations l10n) => [
  l10n.aiSuggestionLessons,
  l10n.aiSuggestionXp,
  l10n.aiSuggestionGames,
  l10n.aiSuggestionBadges,
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
  final List<_AiMessage> _messages = [];
  bool _greeted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_greeted) {
      _greeted = true;
      _messages.add(
        _AiMessage(
          text: AppLocalizations.of(context).aiGreeting,
          isMe: false,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

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
      _messages.add(
        _AiMessage(
          text: _generateResponse(AppLocalizations.of(context), trimmed),
          isMe: false,
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      );
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

  // Anahtar kelime eşleştirmesi hem Türkçe hem İngilizce girdi kabul
  // eder — kullanıcı arayüzü İngilizce'ye çevrilse bile yazdığı soru
  // İngilizce olabileceğinden niyet tespiti iki dilde de çalışmalı.
  String _generateResponse(AppLocalizations l10n, String input) {
    final lower = input.toLowerCase();
    if (lower.contains('merhaba') ||
        lower.contains('selam') ||
        lower.contains('hello') ||
        lower.contains('hi')) {
      return l10n.aiResponseGreeting;
    }
    if (lower.contains('ders') ||
        lower.contains('öğren') ||
        lower.contains('lesson') ||
        lower.contains('learn')) {
      return l10n.aiResponseLessons;
    }
    if (lower.contains('oyun') || lower.contains('game')) {
      return l10n.aiResponseGames;
    }
    if (lower.contains('seviye') ||
        lower.contains('xp') ||
        lower.contains('level')) {
      return l10n.aiResponseXp;
    }
    if (lower.contains('rozet') || lower.contains('badge')) {
      return l10n.aiResponseBadges;
    }
    if (lower.contains('profil') || lower.contains('profile')) {
      return l10n.aiResponseProfile;
    }
    if (lower.contains('yardım') || lower.contains('help')) {
      return l10n.aiResponseHelp;
    }
    return l10n.aiResponseFallback;
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
          // Input bar — kBottomBarHeight + gerçek sistem navigasyon
          // çubuğu yüksekliği kadar yukarı offsetli, böylece floating
          // tab bar (ve 3 tuşlu navigasyonda sistem çubuğu) onu kapatmaz.
          Padding(
            padding: EdgeInsets.only(
              bottom: kBottomBarHeight + MediaQuery.paddingOf(context).bottom,
            ),
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
    final l10n = AppLocalizations.of(context);
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
            l10n.aiPanelTitle,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aiPanelSubtitle,
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
            children: _aiSuggestions(l10n)
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
                hintText: AppLocalizations.of(context).aiInputHint,
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
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
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
              DateFormat.Hm(
                Localizations.localeOf(context).languageCode,
              ).format(time),
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
