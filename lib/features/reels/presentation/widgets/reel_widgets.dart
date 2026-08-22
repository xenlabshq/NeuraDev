import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart'
    show currentAuthUserProvider;
import '../../../../shared/models/user_profile.dart'
    show UserProfile, UserRole;
import '../../../reports/presentation/providers/report_providers.dart';
import '../../domain/entities/game_reel.dart';
import '../providers/reels_providers.dart';
import '../pages/reel_submit_page.dart';

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
          if (reel.videoUrl != null)
            _ReelVideoBackground(videoUrl: reel.videoUrl!)
          else
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

/// Kullanıcı yüklemesi olan reels için gerçek video arka planı — demo
/// modda [videoUrl] yerel dosya yolu, gerçek modda Firebase Storage
/// indirme linki olur. Sessiz + döngülü otomatik oynatma (Reels/TikTok
/// alışkanlığı); dokununca sesi aç/kapat.
class _ReelVideoBackground extends StatefulWidget {
  const _ReelVideoBackground({required this.videoUrl});
  final String videoUrl;

  @override
  State<_ReelVideoBackground> createState() => _ReelVideoBackgroundState();
}

class _ReelVideoBackgroundState extends State<_ReelVideoBackground> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;
  StreamSubscription<YoutubePlayerValue>? _youtubeSub;
  bool _muted = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _ReelVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reel düzenlenip video linki değiştirildiğinde bu widget State'i
    // yeniden kullanılabiliyor (initState tekrar çağrılmaz) — eski
    // controller'ları kapatıp yeni linkle yeniden başlatmazsak eski
    // video (veya eski hata durumu) ekranda takılı kalırdı.
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _failed = false;
      _start();
    }
  }

  void _start() {
    // YouTube linki (izleme sayfası, kısa link, shorts) verilmişse
    // video_player onu hiç oynatamaz — ham video akışı değil, bir web
    // sayfası. Gerçekten uygulama içinde gömülü oynatmak için ayrı bir
    // YouTube iframe player kullanıyoruz; diğer tüm linkler (Storage
    // indirme linki, doğrudan .mp4 vb.) ve yerel dosyalar video_player'a
    // gidiyor.
    final youtubeId = YoutubePlayerController.convertUrlToId(widget.videoUrl);
    if (youtubeId != null) {
      _initYoutube(youtubeId);
    } else {
      _initVideoFile();
    }
  }

  void _disposeControllers() {
    _controller?.dispose();
    _controller = null;
    _youtubeSub?.cancel();
    _youtubeSub = null;
    _youtubeController?.close();
    _youtubeController = null;
  }

  void _initYoutube(String videoId) {
    // `YoutubePlayerController.fromVideoId(...)` KASITLI OLARAK
    // kullanılmıyor — o factory paketin içinde `key: videoId` set
    // ediyor, ve paketin dahili JS köprüsü bu key'i ham bir JavaScript
    // tanımlayıcısına ("Youtube$key") gömüyor. YouTube video ID'leri
    // çoğunlukla tire (-) içerir (ör. "aqz-KE-bpKQ") ki bu geçerli bir
    // JS tanımlayıcısı değildir — sonuç: "ReferenceError: Youtubeaqz is
    // not defined" ile oynatıcı hiç yüklenmiyordu. `key` vermeyerek
    // paketin varsayılanına (hashCode, her zaman JS-güvenli) bırakıyoruz.
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: true,
        loop: false,
        showControls: false,
        showFullscreenButton: false,
        playsInline: true,
        enableKeyboard: false,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
      ),
    );
    controller.loadVideoById(videoId: videoId);
    _youtubeController = controller;
    // Tek bir videoyu Reels tarzı sonsuz döngüde oynatmak için IFrame
    // API'nin kendi `loop` parametresi bir playlist gerektiriyor; onun
    // yerine video bittiğinde başa sarıp yeniden oynatıyoruz.
    _youtubeSub = controller.stream.listen((value) {
      if (value.playerState == PlayerState.ended) {
        controller.seekTo(seconds: 0);
        controller.playVideo();
      }
    });
  }

  Future<void> _initVideoFile() async {
    final isNetwork = widget.videoUrl.startsWith('http');
    final controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));
    _controller = controller;
    try {
      // Kullanıcının yapıştırdığı link ham bir video dosyası değil de
      // bir sayfa linkiyse, initialize() hiç hata fırlatmadan sonsuza
      // kadar bekleyebiliyor — kullanıcı "sürekli yükleniyor" olarak
      // görüyordu. Zaman aşımıyla sınırlayıp "Videoyu Aç" düğmesine
      // düşüyoruz.
      await controller.initialize().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      setState(() {});
    } catch (_) {
      // Bozuk/erişilemez/oynatılamaz video — spinner'da sonsuza kadar
      // takılı kalmak yerine "Videoyu Aç" düğmesine düş; akışın geri
      // kalanı (başlık, CTA, etkileşim butonları) yine çalışır.
      unawaited(controller.dispose());
      if (!mounted) return;
      setState(() {
        _controller = null;
        _failed = true;
      });
    }
  }

  void _toggleMute() {
    final youtube = _youtubeController;
    if (youtube != null) {
      setState(() => _muted = !_muted);
      if (_muted) {
        youtube.mute();
      } else {
        youtube.unMute();
      }
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _muted = !_muted;
      controller.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final youtube = _youtubeController;
    if (youtube != null) {
      return GestureDetector(
        onTap: _toggleMute,
        child: ColoredBox(
          color: const Color(0xFF0A0812),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // YoutubePlayer bir WebView (platform view) barındırıyor —
              // bunu FittedBox ile ölçeklemeye çalışmak YouTube'un kendi
              // oynatıcı script'inde "Cannot read properties of
              // undefined (reading 'setSize')" hatasına yol açıyordu
              // (WebView'a beklenmedik ara boyutlar veriliyordu).
              // Bunun yerine WebView'ın gerçek, stabil boyutlar almasını
              // sağlayan Center + AspectRatio kullanıyoruz — üstte/altta
              // ince siyah şeritler kalabilir ama oynatma güvenilir.
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: youtube,
                    aspectRatio: 16 / 9,
                    enableFullScreenOnVerticalDrag: false,
                  ),
                ),
              ),
              // WebView kendi dokunuşlarını yutuyor — sesi aç/kapat
              // dokunuşunun her yerden çalışması için şeffaf bir
              // dokunma katmanı üstüne biniyor.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleMute,
                ),
              ),
              if (_muted)
                const Positioned(
                  right: 16,
                  top: 100,
                  child: Icon(
                    Icons.volume_off_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final Widget body;
    if (controller != null && controller.value.isInitialized) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          if (_muted)
            const Positioned(
              right: 16,
              top: 100,
              child: Icon(
                Icons.volume_off_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
        ],
      );
    } else if (_failed) {
      // Video oynatılamadı — muhtemelen ham bir video dosyası değil,
      // bilinmeyen bir web sayfası linki. Sonsuza kadar dönen spinner
      // yerine dış tarayıcıda açma seçeneği sun.
      final isNetwork = widget.videoUrl.startsWith('http');
      body = Center(
        child: isNetwork
            ? OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(widget.videoUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  l10n.reelsOpenVideoExternally,
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                ),
              )
            : const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white38,
                size: 40,
              ),
      );
    } else {
      body = const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    return GestureDetector(
      onTap: _toggleMute,
      child: ColoredBox(
        color: const Color(0xFF0A0812),
        child: body,
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
          children: [
            _TabButton(label: AppLocalizations.of(context).reelsFollowingTab),
            const SizedBox(width: 24),
            _TabButton(
              label: AppLocalizations.of(context).reelsDiscoverTab,
              active: true,
            ),
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

  /// Bu reel gerçek bir kullanıcı gönderisiyse (seed/demo içerik değilse)
  /// ve giriş yapılmışsa "⋮" menüsü gösterilir — içerik sahibine
  /// düzenle/sil, staff'a sil, başkasının gönderisine bakan herkese
  /// şikayet et seçeneği sunar (bkz. `_openMenu`).
  bool _canShowMenu(GameReel reel, UserProfile? user) =>
      reel.uploaderId != null && user != null;

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    final l10n = AppLocalizations.of(context);
    final isOwner = reel.uploaderId == user.id;
    final canDelete = isOwner || user.role.isSupportStaff;
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1F1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: Text(
                  l10n.actionEdit,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: Text(
                  l10n.actionDelete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white),
                title: Text(
                  l10n.reelsReportAction,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop('report'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(builder: (_) => ReelSubmitPage(existing: reel)),
      );
    } else if (action == 'delete') {
      await _confirmDelete(context, ref);
    } else if (action == 'report') {
      await _reportReel(context, ref, user);
    }
  }

  Future<void> _reportReel(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reasonCtl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.reelsReportDialogTitle),
          content: TextField(
            controller: reasonCtl,
            autofocus: true,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l10n.reelsReportReasonHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionGiveUp),
            ),
            FilledButton(
              onPressed: reasonCtl.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(reasonCtl.text.trim()),
              child: Text(l10n.reelsReportAction),
            ),
          ],
        ),
      ),
    );
    reasonCtl.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await ref
          .read(reportRepositoryProvider)
          .submitReport(
            reelId: reel.id,
            reelTitle: reel.title,
            reelUploaderId: reel.uploaderId!,
            reporterId: user.id,
            reporterName: user.displayName,
            reason: reason,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsReportSubmitted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsReportFailed(e.toString()))),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reelsDeleteConfirmTitle),
        content: Text(l10n.reelsDeleteConfirmMessage(reel.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionGiveUp),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(reelSubmissionRepositoryProvider).deleteReel(reel.id);
      ref.read(reelsProvider.notifier).removeReel(reel.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsDeleted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsDeleteFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reelsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final user = ref.watch(currentAuthUserProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_canShowMenu(reel, user)) ...[
          _RailIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: l10n.reelsMoreOptions,
            onTap: () => _openMenu(context, ref),
          ),
          const SizedBox(height: 18),
        ],
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
                  label: l10n.reelsFollowAction,
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
          count: _formatCount(reel.likes, isEnglish: isEnglish),
          label: reel.liked ? l10n.reelsLikedLabel : l10n.reelsLikeLabel,
          onTap: () => notifier.toggleLike(reel.id),
        ),
        const SizedBox(height: 18),
        _RailButton(
          icon: const _CommentIcon(),
          count: '${reel.comments.length}',
          label: l10n.reelsCommentsLabel,
          onTap: onOpenComments,
        ),
        const SizedBox(height: 18),
        _RailButton(
          icon: const _ShareIcon(),
          count: l10n.actionShare,
          label: l10n.actionShare,
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

String _formatCount(int n, {required bool isEnglish}) {
  if (n >= 1000) {
    final v = (n / 1000).toStringAsFixed(1);
    final suffix = isEnglish ? 'K' : 'B';
    return '${v.endsWith('.0') ? v.substring(0, v.length - 2) : v}$suffix';
  }
  return '$n';
}

/// `_RailButton` ile aynı sütuna oturan ama sayaç/etiket taşımayan sade
/// ikon düğmesi — reel sahibinin/yöneticinin düzenle/sil menüsü için.
class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x8C14101F),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF382C52)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
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
    final l10n = AppLocalizations.of(context);
    return _RailButton(
      icon: _BookmarkIcon(active: active),
      count: '',
      label: active ? l10n.reelsSavedLabel : l10n.reelsSaveLabel,
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
        _CtaButton(title: reel.title, gameUrl: reel.gameUrl),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.title, required this.gameUrl});
  final String title;
  final String gameUrl;

  /// Kullanıcı gönderimlerinde [gameUrl] gerçek bir https link'tir —
  /// tarayıcıda açılır. Demo seed verisinde uygulama-içi bir rota
  /// (`/lessons` gibi) olduğu için geriye dönük uyumlu şekilde
  /// `context.push` ile açılmaya devam eder.
  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(gameUrl);
    final isExternal =
        uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    if (!isExternal) {
      context.push(gameUrl);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reelsLinkFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFC145),
      child: InkWell(
        onTap: () => _open(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            '▶ ${AppLocalizations.of(context).reelsTryGame}',
            style: const TextStyle(
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
