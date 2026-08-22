import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/reels_providers.dart';
import '../widgets/reel_comments_drawer.dart';
import '../widgets/reel_widgets.dart';
import 'reel_submit_page.dart';

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
    // Sonsuz kaydırma: sona 2 reel kala bir sonraki sayfayı önceden iste.
    final reels = ref.read(reelsProvider);
    if (i >= reels.length - 2) {
      ref.read(reelsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);
    if (reels.isEmpty) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context).reelsEmpty)),
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
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: const _SubmitGameButton(),
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
              // Alt navigation bar + safe area (klavye) üzerinde konumlan.
              // 84 px = HomeShell kBottomBarHeight, + bottom inset klavye.
              bottom: MediaQuery.viewPaddingOf(context).bottom > 0
                  ? MediaQuery.viewInsetsOf(context).bottom
                  : 84 + MediaQuery.paddingOf(context).bottom,
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

/// Kullanıcının kendi oyununu Reels akışına eklemesi için giriş noktası.
/// Reels'i gezmek giriş gerektirmiyor ama gönderim yapmak gerektiriyor —
/// giriş yapmamış kullanıcı burada login ekranına yönlendirilir.
class _SubmitGameButton extends ConsumerWidget {
  const _SubmitGameButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        tooltip: AppLocalizations.of(context).reelsShareYourGame,
        onPressed: () {
          final isAuthed = ref.read(currentAuthUserProvider) != null;
          if (!isAuthed) {
            context.push('/login');
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReelSubmitPage()),
          );
        },
      ),
    );
  }
}
