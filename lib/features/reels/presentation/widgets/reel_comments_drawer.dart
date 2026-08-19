import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_reel.dart';
import '../providers/reels_providers.dart';

class ReelCommentsDrawer extends ConsumerStatefulWidget {
  const ReelCommentsDrawer({
    required this.reel,
    required this.isOpen,
    required this.onClose,
    super.key,
  });

  final GameReel reel;
  final bool isOpen;
  final VoidCallback onClose;

  @override
  ConsumerState<ReelCommentsDrawer> createState() => _ReelCommentsDrawerState();
}

class _ReelCommentsDrawerState extends ConsumerState<ReelCommentsDrawer> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    ref.read(reelsProvider.notifier).addComment(widget.reel.id, text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(reelProvider(widget.reel.id)) ?? widget.reel;
    final mq = MediaQuery.of(context);
    // Yükseklik %68 yerine, klavye açıksa (viewInsets.bottom) onun
    // üstünde bitirip viewport'un %70'ini kaplayacak şekilde sınırla.
    // Çok küçük ekranda minimum 280 px garantisi ver.
    final double maxAllowed = (mq.size.height - mq.viewInsets.bottom) * 0.7;
    final double drawerHeight = widget.isOpen
        ? (maxAllowed < 280 ? 280 : maxAllowed)
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.ease,
      height: drawerHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF201933),
        border: Border(top: BorderSide(color: Color(0xFF382C52))),
      ),
      child: ClipRect(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF382C52))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yorumlar (${current.comments.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    child: const Text(
                      '×',
                      style: TextStyle(color: Color(0xFFA99FC4), fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                itemCount: current.comments.length,
                itemBuilder: (_, i) {
                  final c = current.comments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A1428),
                            border: Border.all(color: const Color(0xFF4A3A6B)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            c.user
                                .replaceAll('@', '')
                                .substring(0, 2)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFA99FC4),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.user,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.text,
                                style: const TextStyle(
                                  color: Color(0xFFA99FC4),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF382C52))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6E6390),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A1428),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A3A6B),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFFFFC145),
                    child: InkWell(
                      onTap: _send,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: const Text(
                          'Gönder',
                          style: TextStyle(
                            color: Color(0xFF14101F),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
