import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/features/learning/domain/entities/learning_island.dart';
import 'package:neuroup/features/learning/domain/entities/learning_memory.dart';
import 'package:neuroup/features/learning/presentation/painters/island_block_painter.dart';
import 'package:neuroup/features/learning/presentation/painters/isometric_camera.dart';
import 'package:neuroup/features/learning/presentation/providers/adaptive_providers.dart';
import 'package:neuroup/features/learning/presentation/providers/learning_providers.dart';
import 'package:neuroup/features/learning/presentation/pages/island_detail_page.dart';

/// Fancade tarzı izometrik ada haritası.
/// 3D blok platformlar üzerinde emoji + durum + ahşap yol çizgileri.
class IslandMapPage extends ConsumerStatefulWidget {
  const IslandMapPage({super.key});

  @override
  ConsumerState<IslandMapPage> createState() => _IslandMapPageState();
}

class _IslandMapPageState extends ConsumerState<IslandMapPage> {
  IsometricCamera _camera = IsometricCamera(viewportSize: Size.zero);
  Offset _lastFocal = Offset.zero;
  String? _hoveredIslandId;
  String? _pressedIslandId;
  bool _introShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_introShown) return;
      final islands = ref.read(islandsProvider);
      final progress = ref.read(learningProgressProvider).progress;
      // İlk kez geldiğinde veya ada yokken → intro göster.
      if (progress.completedNodeIds.isEmpty) {
        _showIntroModal(islands);
      }
    });
  }

  void _showIntroModal(List<LearningIsland> islands) {
    _introShown = true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MapIntroSheet(
        islands: islands,
        onDismiss: () {},
      ),
    );
  }

  void _onPointerDown(PointerDownEvent d) {
    _lastFocal = d.localPosition;
  }

  void _onPointerMove(PointerMoveEvent d) {
    final delta = d.localPosition - _lastFocal;
    _lastFocal = d.localPosition;
    if (delta.distanceSquared > 0.1) {
      setState(() => _camera = _camera.withPan(delta));
    }
  }

  LearningIsland? _hitTest(Offset point, List<LearningIsland> islands) {
    // En öndeki (son çizilen) adayı döndür: listenin sonundan başla.
    for (var i = islands.length - 1; i >= 0; i--) {
      final island = islands[i];
      final pos = _camera.project(island.x, island.y, island.z);
      final size = island.size * _camera.zoom;
      final dx = point.dx - pos.dx;
      final dy = point.dy - (pos.dy - size * 0.25);
      if ((dx.abs() / (size * 0.7) + dy.abs() / (size * 0.35)) <= 1.0) {
        return island;
      }
    }
    return null;
  }

  void _updateHover(Offset point, List<LearningIsland> islands) {
    final hit = _hitTest(point, islands);
    final id = hit?.id;
    if (id != _hoveredIslandId) {
      setState(() => _hoveredIslandId = id);
    }
  }

  void _onTapUp(TapUpDetails d, List<LearningIsland> islands) {
    final hit = _hitTest(d.localPosition, islands);
    if (hit == null) return;
    if (hit.unlocked) {
      // Zayıf ada ise önce "odaklanman gereken dersler" sheet'i göster.
      final weakCount = ref
          .read(adaptiveMemoryProvider.notifier)
          .weakCountForIsland(hit.id);
      if (weakCount > 0) {
        _showFocusSheet(hit.id);
        return;
      }
      Navigator.of(context).push<Widget>(
        MaterialPageRoute<Widget>(
          builder: (_) => IslandDetailPage(islandId: hit.id),
        ),
      );
    } else {
      // Press feedback animasyonu
      setState(() => _pressedIslandId = hit.id);
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() => _pressedIslandId = null);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ada kilitli. Önceki adayı tamamla!')),
      );
    }
  }

  /// Zayıf ada için "odaklanman gereken dersler" bottom sheet.
  /// Spaced repetition motorunun önerdiği node'ları sıralı gösterir.
  void _showFocusSheet(String islandId) {
    final island = ref
        .read(islandsProvider)
        .firstWhereOrNull((i) => i.id == islandId);
    if (island == null) return;
    final mems = island.nodes
        .map((n) => ref.read(nodeMemoryProvider(n.id)))
        .whereType<NodeMemory>()
        .toList();
    // Zayıf + due olan node'ları confidence'a göre sırala
    final focused = mems.where((m) => m.isWeak || m.isDue).toList()
      ..sort((a, b) => a.confidence.compareTo(b.confidence));
    final recommendedId = ref
        .read(adaptiveMemoryProvider.notifier)
        .recommendedNodeFor(islandId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Küçük ekranda taşmayı önlemek için içeriği viewport'un
      // maksimum %75'i ile sınırla. Büyük ekranda serbest büyür.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1330), Color(0xFF221F3D)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.warning, AppColors.error],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🎯', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Odaklanman Gereken Dersler',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            island.title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (focused.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tüm dersler öğrenilmiş görünüyor!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...focused.take(5).map((m) {
                    final node = island.nodes
                        .firstWhereOrNull((n) => n.id == m.nodeId);
                    if (node == null) return const SizedBox.shrink();
                    final isTop = m.nodeId == recommendedId;
                    return _FocusTile(
                      node: node,
                      memory: m,
                      isRecommended: isTop,
                    );
                  }),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          Navigator.of(context).push<Widget>(
                            MaterialPageRoute<Widget>(
                              builder: (_) => IslandDetailPage(islandId: islandId),
                            ),
                          );
                        },
                        child: const Text('Tüm Dersleri Gör'),
                      ),
                    ),
                    if (recommendedId != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(sheetCtx).pop();
                            Navigator.of(context).push<Widget>(
                              MaterialPageRoute<Widget>(
                                builder: (_) => IslandDetailPage(islandId: islandId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Önerilenle Başla'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final islands = ref.watch(islandsProvider);

    // Layout: 10 adayı 2 satıra yerleştir (5+5 zigzag)
    final positioned = _arrangeIslands(islands);

    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      body: Stack(
        children: [
          // 3D sahne + gesture (Listener ile pan, ayrı GestureDetector ile tap)
          LayoutBuilder(
            builder: (context, constraints) {
              _camera = _camera.withViewportSize(
                Size(constraints.maxWidth, constraints.maxHeight),
              );
              if (_camera.center == Offset.zero) {
                _camera = _camera.withPan(const Offset(0, 60));
              }
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: const _IsometricBackgroundPainter(),
                  ),
                  // Derinlik sırası: arkadan öne
                  ..._renderDepthOrdered(positioned),
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: const _IsometricGroundPainter(),
                  ),
                  // Tap layer — sadece tap, recognizer çakışması yok
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _onTapUp(d, positioned),
                    ),
                  ),
                  // Pointer layer — pan/zoom + hover detection.
                  // Listener recognizer değil, tap ile çakışmaz.
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) {
                        _updateHover(e.localPosition, positioned);
                        _onPointerDown(e);
                      },
                      onPointerMove: (e) {
                        _updateHover(e.localPosition, positioned);
                        _onPointerMove(e);
                      },
                      onPointerHover: (e) =>
                          _updateHover(e.localPosition, positioned),
                    ),
                  ),
                ],
              );
            },
          ),
          // HUD: üstte XP ve ilerleme
          _TopHud(islands: islands),
          // Bottom info: zoom indicator + hint (bottom nav yüksekliği kadar yukarı)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HintChip(),
                  _ZoomChip(zoom: 1.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LearningIsland> _arrangeIslands(List<LearningIsland> islands) {
    final sorted = [...islands]..sort((a, b) => a.order.compareTo(b.order));
    final positions = <_PosIsland>[];
    // 10 ada için curling/snaking path (Fancade tarzı).
    // Her satırda 3 ada, toplam 4 satır (en son satırda 1).
    // Satırlar zig zag yapar: sağdan-sola / soldan-sağa,
    // y yükseltilir → kule hissi.
    const colsPerRow = 3;
    final xStep = 200.0;
    final zStep = 150.0;
    final yStep = 22.0;

    for (var i = 0; i < sorted.length; i++) {
      final row = i ~/ colsPerRow;
      final col = i % colsPerRow;
      final isLastRow = row == (sorted.length - 1) ~/ colsPerRow;
      // Satır yönü: çift satır → 0..2 (sol→sağ), tek satır → 2..0 (sağ→sol)
      final colInRow = row.isOdd ? (colsPerRow - 1 - col) : col;
      // Satır tam dolu değilse (son satır) ortala
      final remaining = sorted.length - row * colsPerRow;
      final effectiveCount = isLastRow ? remaining : colsPerRow;
      final centerOffset = (effectiveCount - 1) / 2.0;
      final baseX = (colInRow - centerOffset) * xStep;
      final x = baseX;
      final z = row * zStep;
      final y = row * yStep;
      positions.add(_PosIsland(island: sorted[i], x: x, y: y, z: z));
    }
    return positions
        .map((p) => _PosIsland(
              island: p.island,
              x: p.x,
              y: p.y,
              z: p.z,
            ).islandWithPos)
        .toList();
  }

  List<Widget> _renderDepthOrdered(List<LearningIsland> islands) {
    // y + z'ye göre sırala (arkadan öne)
    final sorted = [...islands]..sort((a, b) => (a.y + a.z).compareTo(b.y + b.z));
    final widgets = <Widget>[];
    // Adaptive engine'den zayıf ada verilerini al.
    // F-08: artık pre-computed map'ten okuyoruz (O(1) lookup).
    final weakByIsland = ref.watch(weakNodesByIslandProvider);
    final islandStats = ref.watch(adaptiveMemoryProvider).islandStatsMap;
    // Önce adalar
    for (final island in sorted) {
      // Sadece açık (unlocked) adalar için hover aktif.
      final hovered = (island.id == _hoveredIslandId) && island.unlocked;
      final weakCount = weakByIsland[island.id]?.length ?? 0;
      final stats = islandStats[island.id];
      final isCritical = stats?.isCritical ?? false;
      final avgConf = stats?.averageConfidence ?? 1.0;
      widgets.add(
        AnimatedScale(
          scale: island.id == _pressedIslandId ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: CustomPaint(
            painter: IslandBlockPainter(
              camera: _camera,
              island: island,
              hovered: hovered,
              weakCount: weakCount,
              isCritical: isCritical,
              averageConfidence: avgConf,
            ),
          ),
        ),
      );
    }
    // Sonra yollar (her ardışık ada çifti arasında)
    // Yol, arka adanın ön adanın üzerinden akarak gerçek 3D köprü hissi verir.
    for (var i = 0; i < islands.length - 1; i++) {
      final from = islands[i];
      final to = islands[i + 1];
      final fromPos = _camera.project(from.x, from.y, from.z);
      final toPos = _camera.project(to.x, to.y, to.z);
      widgets.add(
        CustomPaint(
          painter: IslandPathPainter(
            camera: _camera,
            from: fromPos,
            to: toPos,
            active: from.allCompleted,
          ),
        ),
      );
    }
    return widgets;
  }
}

class _PosIsland {
  _PosIsland({required this.island, required this.x, required this.y, required this.z});
  final LearningIsland island;
  final double x;
  final double y;
  final double z;
  LearningIsland get islandWithPos => LearningIsland(
        id: island.id,
        title: island.title,
        subtitle: island.subtitle,
        description: island.description,
        emoji: island.emoji,
        color: island.color,
        gradient: island.gradient,
        order: island.order,
        nodes: island.nodes,
        size: island.size,
        unlocked: island.unlocked,
        x: x,
        y: y,
        z: z,
      );
}

class _IsometricBackgroundPainter extends CustomPainter {
  const _IsometricBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFB3E5FC),
        Color(0xFFB2EBF2),
        Color(0xFFE0F7FA),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Bulutlar
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final positions = [
      const Offset(80, 90),
      const Offset(280, 60),
      const Offset(420, 110),
      const Offset(120, 360),
      const Offset(380, 380),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, 22, cloudPaint);
      canvas.drawCircle(p + const Offset(18, -6), 14, cloudPaint);
      canvas.drawCircle(p + const Offset(-15, 4), 12, cloudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricBackgroundPainter old) => false;
}

class _IsometricGroundPainter extends CustomPainter {
  const _IsometricGroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Zemin grid (Fancade tarzı yarı saydam grid)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const cellSize = 40.0;
    for (double x = 0; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricGroundPainter old) => false;
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.islands});
  final List<LearningIsland> islands;

  @override
  Widget build(BuildContext context) {
    final completed = islands.where((i) => i.allCompleted).length;
    final total = islands.length;
    final totalNodes = islands.fold<int>(0, (s, i) => s + i.totalNodes);
    final completedNodes =
        islands.fold<int>(0, (s, i) => s + i.completedNodes);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.violet],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.explore_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Python Adaları',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedNodes / $totalNodes ders · $completed / $total ada',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            'Ada için tıkla · sürükle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomChip extends StatelessWidget {
  const _ZoomChip({required this.zoom});
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(zoom * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// İlk kez gelen kullanıcıya harita nasıl kullanılır anlatan
/// yenilikçi intro modal'ı. Adanın %100 tamamlanınca yeni açıldığını
/// ve hex kristal mantığını da açıklar.
class _MapIntroSheet extends StatelessWidget {
  const _MapIntroSheet({required this.islands, required this.onDismiss});
  final List<LearningIsland> islands;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1330), Color(0xFF221F3D)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '🏝️',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Python Adaları',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '10 ada · 50+ interaktif ders',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _IntroStep(
              emoji: '🗺️',
              title: 'Sürükle & Yakınlaştır',
              desc:
                  'Haritayı parmağınla kaydır, iki parmakla yakınlaştır.',
              color: AppColors.primary,
            ),
            _IntroStep(
              emoji: '🔓',
              title: 'Kilidi Açmak İçin Sırayla Git',
              desc:
                  'Her ada bir öncekinin tüm derslerini tamamlayınca açılır.',
              color: AppColors.success,
            ),
            _IntroStep(
              emoji: '💎',
              title: 'Kristalleri Yakala',
              desc:
                  'Her ders bir hex kristal. Tamamladıkça altına döner ve ⭐ alırsın.',
              color: AppColors.gold,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                child: const Text(
                  'Keşfe Başla',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
  });
  final String emoji;
  final String title;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({
    required this.node,
    required this.memory,
    required this.isRecommended,
  });

  final dynamic node;
  final NodeMemory memory;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final pct = (memory.confidence * 100).round();
    final color = isRecommended ? AppColors.warning : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended
            ? AppColors.warning.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecommended
              ? AppColors.warning.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isRecommended ? AppColors.warning : Colors.white)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(node.emoji as String,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.title as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRecommended)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          '⭐ Önerilen',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: memory.confidence,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '%$pct',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}