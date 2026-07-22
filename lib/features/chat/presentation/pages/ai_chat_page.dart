import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/colors.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiMessage> _messages = [
    _AiMessage(
      text:
          'Merhaba! Ben Neuroup AI asistanınım. Öğrenme, dersler, oyunlar '
          'veya uygulama hakkında sorularını yanıtlayabilirim.\n\n'
          'Demo modunda olduğun için cevaplarım önceden hazırlanmış. '
          'Gerçek AI entegrasyonu sonra eklenecek.',
      isMe: false,
      timestamp: DateTime.now(),
    ),
  ];

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final userMsg = _AiMessage(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _input.clear();
    });
    _scrollToBottom();

    // Simulated AI response (1.2s delay)
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(
          text: _generateResponse(text),
          isMe: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('merhaba') || lower.contains('selam') || lower.contains('hi')) {
      return 'Merhaba! Sana nasıl yardımcı olabilirim? '
          'Dersler, oyunlar veya seviye sistemi hakkında soru sorabilirsin.';
    }
    if (lower.contains('nasıl') && lower.contains('oyuna')) {
      return 'Oyunlar sekmesine git, "Kelime Avı" oyununu seç, '
          'karışık harfleri tıklayarak sıraya koy. Doğruysa puan kazanırsın, '
          'üst üste doğru cevaplar bonus XP verir!';
    }
    if (lower.contains('seviye') || lower.contains('level')) {
      return 'XP kazandıkça seviye atlıyorsun. 5 tier var: '
          '🥉 Bronz (1-5), 🥈 Gümüş (6-10), 🥇 Altın (11-20), '
          "💎 Elmas (21-29), 👑 Usta (30+). Her tier'da profil çerçeven değişir!";
    }
    if (lower.contains('rozet') || lower.contains('badge')) {
      return '8 farklı rozet var. İlk dersi tamamlayınca "İlk Adım" rozetini alırsın. '
          '7 gün üst üste giriş yaparsan "7 Gün Seri" rozeti gelir. '
          'Profil sekmesinden tüm rozetlerini görebilirsin.';
    }
    if (lower.contains('harita') || lower.contains('lesson') || lower.contains('ders')) {
      return 'Dersler sekmesinde Fancade tarzı bir harita var. '
          'Her ders bir node. Önceki dersi tamamlayınca sonraki açılıyor. '
          "Node'a tıklayınca quiz başlıyor!";
    }
    if (lower.contains('chat') || lower.contains('destek') || lower.contains('moderatör')) {
      return '"Sohbet" sekmesinde gerçek moderatörlerle görüşebilirsin. '
          'Demo modunda ise AI cevap veriyor.';
    }
    if (lower.contains('profil')) {
      return "Profil sekmesinde avatarın, seviyen, XP'n, rozetlerin ve ayarların var. "
          'Avatar çerçeven seviyene göre Bronz, Gümüş, Altın, Elmas veya Usta görünür.';
    }
    if (lower.contains('yardım') || lower.contains('help')) {
      return 'Yardım için:\n'
          '• "Dersler nasıl çalışır?"\n'
          '• "Oyunları nasıl oynarım?"\n'
          '• "Seviye sistemi nedir?"\n'
          '• "Nasıl rozet kazanırım?"\n\n'
          'Birini seç veya kendi sorunu yaz!';
    }
    if (lower.contains('teşekkür') || lower.contains('sağol') || lower.contains('tşk')) {
      return 'Rica ederim! İyi öğrenmeler 🚀';
    }
    return 'İlginç bir soru! Demo modunda olduğum için sınırlı bilgiye sahibim. '
        '"Yardım" yazarak neler sorabileceğini görebilirsin. '
        'Gerçek AI entegrasyonu sonra eklenecek.';
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
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
                            'AI Asistan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Çevrimiçi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Quick prompts
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hızlı sorular',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickPrompt(
                          text: 'Dersler nasıl çalışır?',
                          onTap: () => _askQuestion('Dersler nasıl çalışır?')),
                      _QuickPrompt(
                          text: 'Oyunları nasıl oynarım?',
                          onTap: () => _askQuestion('Oyunları nasıl oynarım?')),
                      _QuickPrompt(
                          text: 'Seviye sistemi nedir?',
                          onTap: () => _askQuestion('Seviye sistemi nedir?')),
                      _QuickPrompt(
                          text: 'Nasıl rozet kazanırım?',
                          onTap: () => _askQuestion('Nasıl rozet kazanırım?')),
                    ],
                  ),
                ],
              ),
            ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _AiBubble(
                  text: m.text,
                  isMe: m.isMe,
                  time: m.timestamp,
                );
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: InputDecoration(
                        hintText: "AI'a sor...",
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
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
        ],
      ),
    );
  }

  void _askQuestion(String q) {
    _input.text = q;
    _send();
  }
}

class _AiMessage {
  _AiMessage({required this.text, required this.isMe, required this.timestamp});
  final String text;
  final bool isMe;
  final DateTime timestamp;
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });
  final String text;
  final bool isMe;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.accentGradient : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AI ASİSTAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  const _QuickPrompt({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
