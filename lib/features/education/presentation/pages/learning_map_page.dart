import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/models/user_level.dart';
import 'package:neuroup/shared/utils/layout_helper.dart';
import 'package:neuroup/shared/widgets/common_widgets.dart';
import 'package:neuroup/features/education/domain/entities/lesson.dart';
import 'package:neuroup/features/education/domain/entities/user_progress.dart';
import 'package:neuroup/features/education/presentation/providers/education_providers.dart';
import 'package:neuroup/features/education/presentation/pages/quiz_page.dart';

class LearningMapPage extends ConsumerWidget {
  const LearningMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLessons = ref.watch(lessonsStreamProvider);
    final asyncProgress = ref.watch(myLessonProgressProvider);

    return Scaffold(
      body: asyncLessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'Henüz ders yok',
              message: 'Yakında yeni dersler eklenecek.',
            );
          }
          final progressList = asyncProgress.valueOrNull ?? const [];
          final progressMap = {for (final p in progressList) p.lessonId: p};
          final nodes = _buildNodes(lessons, progressMap);

          return CustomScrollView(
            slivers: [
              _MapHeader(
                totalNodes: nodes.length,
                completedNodes: nodes.where((n) => n.isCompleted).length,
              ),
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, c) => _MapCanvas(
                    nodes: nodes,
                    width: c.maxWidth,
                    onTap: (n) => _onNodeTap(context, n),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  void _onNodeTap(BuildContext context, MapNode node) {
    if (node.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu ders kilitli. Önceki dersi tamamla!'),
        ),
      );
      return;
    }
    Navigator.of(context).push<Widget>(
      MaterialPageRoute<Widget>(
        builder: (_) => QuizPage(
          lessonId: node.id,
          lessonTitle: node.lesson.title,
        ),
      ),
    );
  }

  List<MapNode> _buildNodes(
    List<Lesson> lessons,
    Map<String, UserProgress> progress,
  ) {
    final sorted = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
    final result = <MapNode>[];
    for (var i = 0; i < sorted.length; i++) {
      final lesson = sorted[i];
      final prog = progress[lesson.id];
      MapNodeState state;
      if (prog?.isCompleted ?? false) {
        state = MapNodeState.completed;
      } else if (prog?.status == LessonStatus.inProgress ||
          (i == 0 || (progress[sorted[i - 1].id]?.isCompleted ?? false))) {
        state = MapNodeState.available;
      } else {
        state = MapNodeState.locked;
      }
      result.add(MapNode(
        id: lesson.id,
        lesson: lesson,
        rowIndex: i,
        colIndex: i.isEven ? 0 : 1,
        state: state,
        bestScore: prog?.bestScore ?? 0,
      ));
    }
    return result;
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.totalNodes,
    required this.completedNodes,
  });
  final int totalNodes;
  final int completedNodes;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
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
              Positioned(
                right: 40,
                bottom: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Öğrenme Haritası',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedNodes / $totalNodes ders tamamlandı',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.nodes,
    required this.width,
    required this.onTap,
  });

  final List<MapNode> nodes;
  final double width;
  final void Function(MapNode) onTap;

  @override
  Widget build(BuildContext context) {
    final nodeSize = math.min(width * 0.22, 92);
    final rowHeight = nodeSize + 32;
    final padding = LayoutHelper.horizontalPadding(context);
    final centerX = width / 2;

    // Y koordinatları
    final positions = <Offset>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final y = nodeSize * 0.7 + i * rowHeight;
      final x = node.colIndex == 0
          ? centerX - nodeSize * 0.7
          : centerX + nodeSize * 0.7;
      positions.add(Offset(x, y));
    }

    final totalHeight = nodeSize + (nodes.length - 1) * rowHeight + 32;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Path lines between nodes
            Positioned.fill(
              child: CustomPaint(
                painter: _PathPainter(
                  positions: positions,
                  nodeSize: nodeSize,
                  nodeStates: nodes.map((n) => n.state).toList(),
                ),
              ),
            ),
            // Nodes
            for (var i = 0; i < nodes.length; i++)
              Positioned(
                left: positions[i].dx - nodeSize / 2,
                top: positions[i].dy,
                child: _MapNodeWidget(
                  node: nodes[i],
                  size: nodeSize,
                  onTap: () => onTap(nodes[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.positions,
    required this.nodeSize,
    required this.nodeStates,
  });

  final List<Offset> positions;
  final double nodeSize;
  final List<MapNodeState> nodeStates;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < positions.length - 1; i++) {
      final p1 = positions[i];
      final p2 = positions[i + 1];
      final isCompleted = nodeStates[i] == MapNodeState.completed &&
          nodeStates[i + 1] != MapNodeState.locked;

      final paint = Paint()
        ..color = isCompleted
            ? AppColors.success
            : AppColors.border
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Dashed line for locked, solid for completed
      if (!isCompleted) {
        _drawDashedLine(canvas, p1, p2, paint, nodeSize);
      } else {
        // Smooth curve
        final path = Path()
          ..moveTo(p1.dx, p1.dy + nodeSize / 2)
          ..cubicTo(
            p1.dx,
            p1.dy + nodeSize / 2 + rowHeight(nodeSize) / 2,
            p2.dx,
            p2.dy - nodeSize / 2 - rowHeight(nodeSize) / 2,
            p2.dx,
            p2.dy - nodeSize / 2,
          );
        canvas.drawPath(path, paint);
      }
    }
  }

  double rowHeight(double nodeSize) => nodeSize + 32;

  void _drawDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint, double nodeSize) {
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final distance = (p2 - p1).distance;
    final direction = (p2 - p1) / distance;
    double drawn = 0;
    final var current = Offset(p1.dx, p1.dy + nodeSize / 2);

    while (drawn < distance) {
      final segmentEnd = math.min(drawn + dashWidth, distance);
      final start = current + direction * (drawn - 0);
      final end = current + direction * (segmentEnd - 0);
      canvas.drawLine(start, end, paint);
      drawn = segmentEnd + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => false;
}

class _MapNodeWidget extends StatelessWidget {
  const _MapNodeWidget({
    required this.node,
    required this.size,
    required this.onTap,
  });
  final MapNode node;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(node.state);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size + 24,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    node.lesson.thumbnailEmoji,
                    style: TextStyle(
                      fontSize: size * 0.42,
                      color: node.state == MapNodeState.locked
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.white,
                    ),
                  ),
                  if (node.isCompleted)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: size * 0.32,
                        height: size * 0.32,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (node.isLocked)
                    Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: size * 0.3,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              node.lesson.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (node.bestScore > 0)
              Text(
                '${node.bestScore}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(MapNodeState state) => switch (state) {
        MapNodeState.locked => AppColors.textTertiary,
        MapNodeState.available => AppColors.primary,
        MapNodeState.inProgress => AppColors.warning,
        MapNodeState.completed => AppColors.success,
      };
}
