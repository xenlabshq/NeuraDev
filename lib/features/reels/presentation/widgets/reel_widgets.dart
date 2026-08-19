import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/game_reel.dart';
import '../providers/reels_providers.dart';

/// Reel arka planı: radial gradient + scanlines + vignette + code sembolleri.
class ReelBackgroundPainter extends CustomPainter {
  ReelBackgroundPainter({
    required this.accent,
    required this.symbols,
  });

  final ReelAccent accent;
  final List<String> symbols;

  @override
  void paint(Canvas canvas, Size size) {
    final color = accent.color;
    final accentRgb = (color.red, color.green, color.blue);

    final gradient = RadialGradient(
      center: const Alignment(-0.4, -0.6),
      radius: 0.95,
      colors: [
        Color.fromARGB(
          (color.alpha * 0.38).round().clamp(0, 255),
          color.red,
          color.green,
          color.blue,
        ),
        const Color(0xFF1A1428),
      ],
      stops: const [0.0, 0.72],
    );

    final rect = Offset.zero & size;
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    final scanPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var y = 0; y < size.height; y += 3) {
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(size.width, y.toDouble()),
        scanPaint,
      );
    }

    final vignette = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0x000A0812), const Color(0xEB0A0812)],
      stops: const [0.38, 1.0],
    );
    final vPaint = Paint()..shader = vignette.createShader(rect);
    canvas.drawRect(rect, vPaint);

    final symPaint = Paint()
      ..color = Color.fromARGB(43, accentRgb.$1, accentRgb.$2, accentRgb.$3);
    final positions = [
      const Offset(0.10, 0.14),
      const Offset(0.72, 0.30),
      const Offset(0.16, 0.52),
      const Offset(0.58, 0.44),
    ];
    final sizes = [26.0, 34.0, 20.0, 22.0];
    for (var i = 0; i < symbols.length && i < positions.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: symbols[i],
          style: TextStyle(
            color: symPaint.color,
            fontSize: sizes[i],
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final pos = positions[i];
      tp.paint(
        canvas,
        Offset(
          size.width * pos.dx - tp.width / 2,
          size.height * pos.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReelBackgroundPainter old) =>
      old.accent != accent || old.symbols != symbols;
}

/// Tek bir reel'i (tam ekran) gösteren widget.
class ReelPage extends StatelessWidget {
  const ReelPage({
    required this.reel,
    required this.onOpenComments,
    super.key,
  });

  final GameReel reel;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ReelBackgroundPainter(
              accent: reel.accent,
              symbols: reel.symbols,
            ),
          ),
          _TopTabs(),
          Positioned(
            top: mq.padding.top + 56,
            left: 16,
            child: _HudChip(text: reel.hud),
          ),
          Positioned(
            right: 12,
            bottom: 110,
            child: _ActionRail(
              reel: reel,
              onOpenComments: onOpenComments,
            ),
          ),
          Positioned(
            left: 16,
            right: 78,
            bottom: 96,
            child: _BottomInfo(reel: reel),
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 8,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xA60A0812), Color(0x000A0812)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _TabButton(label: 'Takip Ettiklerim'),
            SizedBox(width: 24),
            _TabButton(label: 'Keşfet', active: true),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? const Color(0xFFFFC145) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF6E6390),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x8C14101F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF382C52)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFA99FC4),
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ActionRail extends ConsumerWidget {
  const _ActionRail({required this.reel, required this.onOpenComments});
  final GameReel reel;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reelsProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reel.accent.color,
                border: Border.all(color: const Color(0xFF14101F), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                reel.avatarText,
                style: const TextStyle(
                  color: Color(0xFF14101F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!reel.following)
              Positioned(
                bottom: -4,
                left: 13,
                child: Semantics(
                  label: 'Takip et',
                  button: true,
                  child: GestureDetector(
                    onTap: () => notifier.toggleFollow(reel.id),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFC145),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+',
                        style: TextStyle(
                          color: Color(0xFF14101F),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _RailButton(
          active: reel.liked,
          icon: _HeartIcon(active: reel.liked),
          count: _formatCount(reel.likes),
          label: reel.liked ? 'Beğenildi' : 'Beğen',
          onTap: () => notifier.toggleLike(reel.id),
        ),
        const SizedBox(height: 18),
        _RailButton(
          icon: const _CommentIcon(),
          count: '${reel.comments.length}',
          label: 'Yorumlar',
          onTap: onOpenComments,
        ),
        const SizedBox(height: 18),
        _RailButton(
          icon: const _ShareIcon(),
          count: 'Paylaş',
          label: 'Paylaş',
          onTap: () {},
        ),
        const SizedBox(height: 18),
        _SaveButton(
          active: reel.saved,
          onTap: () => notifier.toggleSave(reel.id),
        ),
      ],
    );
  }
}

String _formatCount(int n) {
  if (n >= 1000) {
    final v = (n / 1000).toStringAsFixed(1);
    return '${v.endsWith('.0') ? v.substring(0, v.length - 2) : v}B';
  }
  return '$n';
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.count,
    required this.onTap,
    required this.label,
    this.active = false,
  });
  final Widget icon;
  final String count;
  final VoidCallback onTap;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: active,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 30, height: 30, child: icon),
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  color: Color(0xFFA99FC4),
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap, required this.active});
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return _RailButton(
      icon: _BookmarkIcon(active: active),
      count: '',
      label: active ? 'Kaydedildi' : 'Kaydet',
      onTap: onTap,
      active: active,
    );
  }
}

class _HeartIcon extends StatelessWidget {
  const _HeartIcon({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeartPainter(active: active),
      size: const Size(26, 26),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.5, h * 0.7, w * 0.05, h * 0.55, w * 0.1, h * 0.3);
    path.cubicTo(w * 0.12, h * 0.18, w * 0.28, h * 0.1, w * 0.5, h * 0.3);
    path.cubicTo(w * 0.72, h * 0.1, w * 0.88, h * 0.18, w * 0.9, h * 0.3);
    path.cubicTo(w * 0.95, h * 0.55, w * 0.5, h * 0.7, w * 0.5, h * 0.85);
    path.close();

    final paint = Paint()
      ..color = active ? const Color(0xFFFF6B6B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => old.active != active;
}

class _CommentIcon extends StatelessWidget {
  const _CommentIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CommentPainter(), size: const Size(26, 26));
  }
}

class _CommentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 3.0;
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h * 0.7);
    path.quadraticBezierTo(w, h * 0.85, w * 0.85, h * 0.85);
    path.lineTo(w * 0.4, h * 0.85);
    path.lineTo(w * 0.3, h);
    path.lineTo(w * 0.3, h * 0.85);
    path.lineTo(r, h * 0.85);
    path.quadraticBezierTo(0, h * 0.85, 0, h * 0.7);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CommentPainter old) => false;
}

class _ShareIcon extends StatelessWidget {
  const _ShareIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SharePainter(), size: const Size(26, 26));
  }
}

class _SharePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.5),
      size.width * 0.12,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.18),
      size.width * 0.12,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.82),
      size.width * 0.12,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.45),
      Offset(size.width * 0.68, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.55),
      Offset(size.width * 0.68, size.height * 0.76),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SharePainter old) => false;
}

class _BookmarkIcon extends StatelessWidget {
  const _BookmarkIcon({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BookmarkPainter(active: active),
      size: const Size(26, 26),
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  _BookmarkPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? const Color(0xFFFFC145) : Colors.white
      ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.18, 0);
    path.lineTo(w * 0.82, 0);
    path.lineTo(w * 0.82, h);
    path.lineTo(w * 0.5, h * 0.78);
    path.lineTo(w * 0.18, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BookmarkPainter old) => old.active != active;
}

class _BottomInfo extends StatelessWidget {
  const _BottomInfo({required this.reel});
  final GameReel reel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reel.devTag,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x9914101F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF382C52)),
          ),
          child: Text(
            reel.title,
            style: TextStyle(
              color: reel.accent.color,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reel.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF3EFFB),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          reel.tags,
          style: const TextStyle(
            color: Color(0xFFFFC145),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        _CtaButton(title: reel.title, route: reel.gameUrl),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.title, required this.route});
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFC145),
      child: InkWell(
        onTap: () => context.push(route),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: const Text(
            '▶ Oyunu Dene',
            style: TextStyle(
              color: Color(0xFF14101F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
