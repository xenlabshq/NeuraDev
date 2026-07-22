import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';

/// AI Asistan paneli — yerel echo cevaplar (8 hazır intent).
class AiAssistantPanel extends ConsumerStatefulWidget {
  const AiAssistantPanel({super.key});

  @override
  ConsumerState<AiAssistantPanel> createState() =>
      _AiAssistantPanelState();
}

class _AiAssistantPanelState extends ConsumerState<AiAssistantPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiMessage> _messages = [
    const _AiMessage(
      text:
          'Merhaba! Ben Neuroup AI asistanıyım. Öğrenme, dersler, oyunlar veya hesap ile ilgili sorularına yardımcı olabilirim.',
      isMe: false,
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_AiMessage(text: text, isMe: true));
      _messages.add(_AiMessage(text: _generateResponse(text), isMe: false));
      _input.clear();
    });
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
    return Container(
      color: const Color(0xFF0A0812),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _AiBubble(
                text: _messages[i].text,
                isMe: _messages[i].isMe,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF14101F),
              border: Border(
                top: BorderSide(
                  color: Color(0x10FFFFFF),
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
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'AI\'a sor...',
                        hintStyle: const TextStyle(
                            color: Color(0xFFB8AED1), fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.info,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMessage {
  const _AiMessage({required this.text, required this.isMe});
  final String text;
  final bool isMe;
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text, required this.isMe});
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          color: isMe ? null : const Color(0xFF2A2440),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: isMe
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}