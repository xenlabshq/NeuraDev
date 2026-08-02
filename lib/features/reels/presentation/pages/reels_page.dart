import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reels_providers.dart';
import '../widgets/reel_comments_drawer.dart';
import '../widgets/reel_widgets.dart';

class ReelsPage extends ConsumerStatefulWidget {
  const ReelsPage({super.key});

  @override
  ConsumerState<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends ConsumerState<ReelsPage> {
  final _pageController = PageController();
  int _currentIndex = 0;
  String? _activeCommentsReelId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openComments(String reelId) {
    setState(() => _activeCommentsReelId = reelId);
  }

  void _closeComments() {
    setState(() => _activeCommentsReelId = null);
  }

  void _onPageChanged(int i) {
    setState(() => _currentIndex = i);
    if (_activeCommentsReelId != null) _closeComments();
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);
    if (reels.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Henüz reel yok')),
      );
    }

    final activeReel = _activeCommentsReelId == null
        ? null
        : reels.firstWhereOrNull((r) => r.id == _activeCommentsReelId);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => ReelPage(
              reel: reels[i],
              onOpenComments: () => _openComments(reels[i].id),
            ),
          ),
          Positioned(
            top: 0,
            right: 4,
            bottom: 200,
            child: IgnorePointer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(reels.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    height: i == _currentIndex ? 22 : 8,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (activeReel != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ReelCommentsDrawer(
                reel: activeReel,
                isOpen: _activeCommentsReelId != null,
                onClose: _closeComments,
              ),
            ),
        ],
      ),
    );
  }
}