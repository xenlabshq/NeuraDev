import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroup/app/router/home_shell.dart'
    show kBottomBarHeight, LessonOverlayScope;

import '../../../../app/theme/colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/utils/layout_helper.dart';
import '../../domain/entities/learning_island.dart';
import '../providers/learning_providers.dart';
import 'node_editor_page.dart';

/// Fütüristik tema aksan rengi — tamamlanmış düğüm/platform enerji
/// halkası, çerçevesi ve rozetleri için (eski "altın" temayı değiştirir).
const _energyColor = Color(0xFF22D3EE);

class IslandDetailPage extends ConsumerStatefulWidget {
  const IslandDetailPage({required this.islandId, super.key});
  final String islandId;

  @override
  ConsumerState<IslandDetailPage> createState() => _IslandDetailPageState();
}

class _IslandDetailPageState extends ConsumerState<IslandDetailPage> {
  LessonOverlayScope? _overlayScope;

  @override
  void initState() {
    super.initState();
    // Shell altındaki floating tab bar'ı gizle: bu sayfa push'lı
    // tam ekran ders detayıdır. Dispose'da sayacı geri al.
    _overlayScope = LessonOverlayScope(context);
  }

  @override
  void dispose() {
    _overlayScope?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final islandId = widget.islandId;
    final islands = ref.watch(islandsProvider);
    final island = islands.firstWhereOrNull((i) => i.id == islandId);
    final l10n = AppLocalizations.of(context);
    if (island == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.islandNotFoundTitle)),
        body: Center(child: Text(l10n.islandNotFoundBody(islandId))),
      );
    }
    final notifier = ref.read(learningProgressProvider.notifier);
    final nodes = notifier.nodesWithState(island);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  island.color.withValues(alpha: 0.3),
                  island.gradient.last.withValues(alpha: 0.4),
                  Colors.white,
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              _IslandHeader(island: island, nodes: nodes),
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, c) => _SnakeNodesMap(
                    island: island,
                    nodes: nodes,
                    width: c.maxWidth,
                    onTap: (i) => _onNodeTap(context, nodes[i]),
                  ),
                ),
              ),
              // Yüzen alt bar + gerçek sistem navigasyon çubuğu yüksekliği
              // kadar güvenlik payı — sabit değer 3 tuşlu navigasyonda
              // yetersiz kalıp son node'ların barın altında kalmasına
              // yol açıyordu.
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      kBottomBarHeight +
                      36 +
                      MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onNodeTap(BuildContext context, LearningNode node) {
    final l10n = AppLocalizations.of(context);
    if (node.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lessonLockedMessage)),
      );
      return;
    }
    if (node.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lessonAlreadyCompletedMessage)),
      );
    }
    Navigator.of(context).push<Widget>(
      MaterialPageRoute<Widget>(
        builder: (_) => NodeEditorPage(
          islandId: widget.islandId,
          nodeId: node.id,
        ),
      ),
    );
  }
}

class _IslandHeader extends StatelessWidget {
  const _IslandHeader({required this.island, required this.nodes});
  final LearningIsland island;
  final List<LearningNode> nodes;

  @override
  Widget build(BuildContext context) {
    final completed = nodes.where((n) => n.isCompleted).length;
    final progress = nodes.isEmpty ? 0.0 : completed / nodes.length;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: island.color,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: island.gradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        island.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        island.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        island.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              // Sayfa açılırken ilerleme çubuğu 0'dan gerçek
                              // değerine doğru canlanarak dolar — sayfanın
                              // ilk anda "diri" hissettirmesi için.
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                      value: value,
                                      minHeight: 8,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$completed / ${nodes.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fancade tarzı ada içi node haritası.
class _SnakeNodesMap extends StatelessWidget {
  const _SnakeNodesMap({
    required this.island,
    required this.nodes,
    required this.width,
    required this.onTap,
  });

  final LearningIsland island;
  final List<LearningNode> nodes;
  final double width;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final padding = LayoutHelper.horizontalPadding(context);
    final canvasWidth = width - padding * 2;
    // Node boyutu — ada haritasından biraz küçük
    final nodeSize = math.min(canvasWidth * 0.20, 80.0);
    final rowHeight = nodeSize * 1.4;
    final totalHeight = nodeSize + (nodes.length - 1) * rowHeight + 40;

    // Zigzag pozisyonlar — sağ-sol
    final positions = <_NodePosition>[];
    for (var i = 0; i < nodes.length; i++) {
      final y = nodeSize / 2 + 30 + i * rowHeight;
      final isRight = i.isEven;
      final x = isRight ? canvasWidth * 0.72 : canvasWidth * 0.28;
      positions.add(
        _NodePosition(
          index: i,
          x: x,
          y: y,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Yol çizgileri
            Positioned.fill(
              child: CustomPaint(
                painter: _SnakeNodesPathPainter(
                  positions: positions,
                  nodeSize: nodeSize,
                ),
              ),
            ),
            // Node'lar
            for (final pos in positions)
              Positioned(
                left: pos.x - nodeSize / 2,
                top: pos.y - nodeSize / 2,
                child: _NodeCircle(
                  node: nodes[pos.index],
                  island: island,
                  size: nodeSize,
                  onTap: () => onTap(pos.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NodePosition {
  const _NodePosition({required this.index, required this.x, required this.y});
  final int index;
  final double x;
  final double y;
}

class _SnakeNodesPathPainter extends CustomPainter {
  _SnakeNodesPathPainter({
    required this.positions,
    required this.nodeSize,
  });
  final List<_NodePosition> positions;
  final double nodeSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < positions.length - 1; i++) {
      final p1 = positions[i];
      final p2 = positions[i + 1];
      final start = Offset(p1.x, p1.y + nodeSize / 2 - 2);
      final end = Offset(p2.x, p2.y - nodeSize / 2 + 2);
      final midY = (start.dy + end.dy) / 2;

      // Yumuşak eğri
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx,
          midY,
          end.dx,
          midY,
          end.dx,
          end.dy,
        );

      // Enerji hattı — dış haritadaki holografik bağlantılarla aynı
      // cyan/tech paleti.
      final paint = Paint()
        ..shader =
            const LinearGradient(
              colors: [Color(0xFF67E8F9), Color(0xFF0891B2)],
            ).createShader(
              Rect.fromPoints(
                Offset(p1.x, p1.y),
                Offset(p2.x, p2.y),
              ),
            )
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeNodesPathPainter old) => false;
}

class _NodeCircle extends StatefulWidget {
  const _NodeCircle({
    required this.node,
    required this.island,
    required this.size,
    required this.onTap,
  });
  final LearningNode node;
  final LearningIsland island;
  final double size;
  final VoidCallback onTap;

  @override
  State<_NodeCircle> createState() => _NodeCircleState();
}

class _NodeCircleState extends State<_NodeCircle>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  late final Animation<double> _rotate;
  // Dokununca hafifçe küçülüp geri sıçrayan "basılı" hissi — dokunmanın
  // gerçekten bir şeyi tetiklediğini anında hissettirir.
  late final AnimationController _pressCtrl;
  late final Animation<double> _press;
  // Kilitli bir node'a dokununca sağa-sola sallanarak "hayır" der —
  // sessizce hiçbir şey olmaması yerine net bir görsel geri bildirim.
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_ctrl);
    if (!widget.node.isCompleted && !widget.node.isLocked) {
      _ctrl.repeat(reverse: true);
    }
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _press = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pressCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.node.isLocked) return;
    _pressCtrl.forward();
  }

  void _handleTapUp(TapUpDetails _) => _pressCtrl.reverse();

  void _handleTapCancel() => _pressCtrl.reverse();

  void _handleTap() {
    if (widget.node.isLocked) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final islandColor = widget.island.color;
    final completed = widget.node.isCompleted;
    final locked = widget.node.isLocked;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, _shakeCtrl]),
        builder: (context, child) {
          final t = _shakeCtrl.value;
          final shakeDx = math.sin(t * math.pi * 5) * (1 - t) * 9;
          return Transform.translate(
            offset: Offset(shakeDx, 0),
            child: Transform.scale(scale: _press.value, child: child),
          );
        },
        child: SizedBox(
          width: widget.size + 20,
          height: widget.size + 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Pulse glow (aktif node'lar için)
              if (!completed && !locked)
                Positioned(
                  top: 8,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      return Container(
                        width: widget.size * _pulse.value + 24,
                        height: widget.size * _pulse.value + 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              islandColor.withValues(alpha: 0.35),
                              islandColor.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Tamamlanmış: enerji halkası
              if (completed)
                Positioned(
                  top: 4,
                  child: Container(
                    width: widget.size + 24,
                    height: widget.size + 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _energyColor.withValues(alpha: 0.4),
                          _energyColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              // Ana hexagonal kristal
              Positioned(
                top: 12,
                child: AnimatedBuilder(
                  animation: _rotate,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: locked ? 0 : _rotate.value * 0.05,
                      child: child,
                    );
                  },
                  child: _HexCrystal(
                    size: widget.size,
                    islandColor: islandColor,
                    completed: completed,
                    locked: locked,
                    emoji: widget.node.emoji,
                  ),
                ),
              ),
              // Tamamlandı rozeti
              if (completed)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: _energyColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              // Alt etiket
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: locked
                          ? [const Color(0xFFE5E7EB), const Color(0xFFC9C9C9)]
                          : [Colors.white, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: locked
                        ? null
                        : [
                            BoxShadow(
                              color: islandColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Text(
                    widget.node.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: locked ? AppColors.textSecondary : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hexagonal kristal — Code Garden konseptinin ana görseli.
/// Aktif: ada rengi parıltı, tamamlanmış: altın, kilitli: küçük kubbe.
class _HexCrystal extends StatelessWidget {
  const _HexCrystal({
    required this.size,
    required this.islandColor,
    required this.completed,
    required this.locked,
    required this.emoji,
  });

  final double size;
  final Color islandColor;
  final bool completed;
  final bool locked;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final fillColor = completed
        ? islandColor
        : (locked ? const Color(0xFF8B8499) : islandColor);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ana hexagon gövdesi
          CustomPaint(
            size: Size(size, size),
            painter: _HexPainter(
              fillColor: fillColor,
              borderColor: completed
                  ? _energyColor
                  : (locked ? const Color(0xFF6B6480) : Colors.white),
              borderWidth: completed ? 3 : 2.5,
              shadow: !locked,
              islandColor: islandColor,
              completed: completed,
            ),
          ),
          // İçerik (emoji veya kilit)
          if (locked)
            const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 22,
            )
          else
            Text(
              completed ? '✓' : emoji,
              style: TextStyle(
                fontSize: completed ? size * 0.5 : size * 0.42,
                color: Colors.white,
                fontWeight: completed ? FontWeight.w900 : null,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadow,
    required this.islandColor,
    required this.completed,
  });

  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final bool shadow;
  final Color islandColor;
  final bool completed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    // Hexagon points (flat-top)
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final x = cx + r * 0.95 * math.cos(angle);
      final y = cy + r * 0.95 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Gradient fill
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: completed
            ? [
                Color.lerp(fillColor, Colors.white, 0.3)!,
                fillColor,
                Color.lerp(fillColor, _energyColor, 0.45)!,
              ]
            : [
                Color.lerp(fillColor, Colors.white, 0.35)!,
                fillColor,
                Color.lerp(fillColor, Colors.black, 0.25)!,
              ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawPath(path, gradPaint);

    // Tamamlanmış: dıştan ikinci, ince bir "tech frame" halkası —
    // holografik bir çerçeve gibi hex'in etrafında hafifçe daha geniş.
    if (completed) {
      final framePath = Path();
      for (var i = 0; i < 6; i++) {
        final angle = -math.pi / 2 + i * math.pi / 3;
        final x = cx + r * 1.12 * math.cos(angle);
        final y = cy + r * 1.12 * math.sin(angle);
        if (i == 0) {
          framePath.moveTo(x, y);
        } else {
          framePath.lineTo(x, y);
        }
      }
      framePath.close();
      canvas.drawPath(
        framePath,
        Paint()
          ..color = _energyColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // İç parlama (highlight) — sol üstte
    final highlight = Path();
    final hAngle = -math.pi / 2 - 0.5;
    final hx = cx + r * 0.55 * math.cos(hAngle);
    final hy = cy + r * 0.55 * math.sin(hAngle);
    highlight.moveTo(hx, hy);
    for (var i = 0; i < 3; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final x = cx + r * 0.45 * math.cos(a);
      final y = cy + r * 0.45 * math.sin(a);
      highlight.lineTo(x, y);
    }
    highlight.close();
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Tamamlanmış: hex köşelerinde küçük "data port" uçları — devre
    // kartı üzerindeki bağlantı pinleri gibi, eski ışıltı parçacıkları
    // yerine.
    if (completed) {
      final portPaint = Paint()
        ..color = _energyColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      for (var i = 0; i < 6; i += 2) {
        final angle = -math.pi / 2 + i * math.pi / 3;
        final px = cx + (r + 5) * math.cos(angle);
        final py = cy + (r + 5) * math.sin(angle);
        canvas.drawCircle(Offset(px, py), 2.2, portPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.completed != completed;
}
