import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/home_shell.dart' show LessonOverlayScope;
import '../../../../app/theme/colors.dart';
import '../../../../core/env/env.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/entities/game_reel.dart';
import '../providers/reels_providers.dart';

/// Kullanıcının kendi oyununu (başlık + tanıtım + oyun linki) Reels
/// akışına eklemesini sağlayan form. Herhangi bir giriş yapmış kullanıcı
/// erişebilir — staff-only değil, çünkü bu bir moderasyon aracı değil,
/// normal kullanıcı içerik gönderim akışı.
class ReelSubmitPage extends ConsumerStatefulWidget {
  const ReelSubmitPage({this.existing, super.key});

  /// Doluysa sayfa düzenleme modunda açılır — alanlar önceden doldurulur,
  /// yayınla yerine güncelle çalışır. `null` ise yeni gönderim modu.
  final GameReel? existing;

  @override
  ConsumerState<ReelSubmitPage> createState() => _ReelSubmitPageState();
}

class _ReelSubmitPageState extends ConsumerState<ReelSubmitPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _caption;
  late final TextEditingController _tags;
  late final TextEditingController _gameUrl;
  late final TextEditingController _videoUrl;
  bool _saving = false;
  XFile? _video;
  LessonOverlayScope? _overlayScope;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _caption = TextEditingController(text: e?.caption ?? '');
    _tags = TextEditingController(text: e?.tags ?? '');
    _gameUrl = TextEditingController(text: e?.gameUrl ?? '');
    // Storage'a dosya yüklemek yerine kullanıcı hazır bir video linki
    // (YouTube, Drive vb.) de yapıştırabilir — Storage gerektirmez,
    // ücretsiz Firebase planında da çalışır.
    _videoUrl = TextEditingController(
      text: e != null && e.videoUrl != null ? e.videoUrl! : '',
    );
    // Shell altındaki floating tab bar'ı gizle — aksi halde gönder
    // düğmesi barın altında kalıyordu.
    _overlayScope = LessonOverlayScope(context);
  }

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    _tags.dispose();
    _gameUrl.dispose();
    _videoUrl.dispose();
    _overlayScope?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _video = picked);
  }

  String? _requiredField(String? v) =>
      (v == null || v.trim().isEmpty)
      ? AppLocalizations.of(context).fieldRequired
      : null;

  String? _validateUrl(String? v) {
    final required = _requiredField(v);
    if (required != null) return required;
    final uri = Uri.tryParse(v!.trim());
    if (uri == null || !(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) {
      return AppLocalizations.of(context).reelsInvalidUrl;
    }
    return null;
  }

  /// Video linki opsiyonel (video dosyası seçilmişse hiç doldurulmayabilir)
  /// — ama doluysa geçerli bir http(s) link olmalı.
  String? _validateOptionalUrl(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) {
      return AppLocalizations.of(context).reelsInvalidUrl;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentAuthUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsSignInFirst)),
      );
      return;
    }
    final videoUrlText = _videoUrl.text.trim();
    // Düzenlerken video zorunlu değil — mevcut video korunur, sadece
    // değiştirmek isteyen kullanıcı yeniden seçebilir. Yeni gönderimde
    // ya bir dosya seçilmiş ya da bir video linki girilmiş olmalı.
    if (!_isEditing && _video == null && videoUrlText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsPickVideoFirst)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final existing = widget.existing!;
        // Öncelik: yeni seçilen dosya > girilen link > mevcut video.
        final videoUrl = _video != null
            ? existing.videoUrl
            : (videoUrlText.isNotEmpty ? videoUrlText : existing.videoUrl);
        final updated = GameReel(
          id: existing.id,
          devName: existing.devName,
          devTag: existing.devTag,
          title: _title.text.trim(),
          caption: _caption.text.trim(),
          tags: _tags.text.trim(),
          accent: existing.accent,
          symbols: existing.symbols,
          hud: existing.hud,
          likes: existing.likes,
          gameUrl: _gameUrl.text.trim(),
          videoUrl: videoUrl,
          uploaderId: existing.uploaderId,
          comments: existing.comments,
        );
        await ref
            .read(reelSubmissionRepositoryProvider)
            .updateReel(updated, localVideoPath: _video?.path);
      } else {
        final accents = ReelAccent.values;
        final accent = accents[Random().nextInt(accents.length)];
        final tag = user.displayName.trim().isEmpty
            ? '@${l10n.reelsFallbackUserTag}'
            : '@${user.displayName.trim().toLowerCase().replaceAll(' ', '')}';
        // Üç video kaynağı önceliği: 1) galeriden seçilen dosya (demo
        // modda yerel yol doğrudan yazılır, gerçek modda Storage'a
        // yüklenip indirme linki repository tarafından yazılır — bkz.
        // `localVideoPath`), 2) kullanıcının yapıştırdığı hazır video
        // linki (Storage'a hiç dokunmaz, ücretsiz plan için de çalışır),
        // 3) hiçbiri yoksa `videoUrl` boş kalır (seed reels gibi arka
        // plan deseni gösterilir).
        final usingLocalFile = _video != null;
        final reel = GameReel(
          id: '',
          devName: user.displayName.trim().isEmpty
              ? l10n.reelsFallbackUserName
              : user.displayName.trim(),
          devTag: tag,
          title: _title.text.trim(),
          caption: _caption.text.trim(),
          tags: _tags.text.trim(),
          accent: accent,
          symbols: const ['🎮', '▶', 'GO'],
          hud: l10n.reelsNewCommunityHud,
          likes: 0,
          gameUrl: _gameUrl.text.trim(),
          videoUrl: usingLocalFile
              ? (Env.firebaseConfigured ? null : _video!.path)
              : (videoUrlText.isNotEmpty ? videoUrlText : null),
          uploaderId: user.id,
          comments: const [],
        );
        await ref
            .read(reelSubmissionRepositoryProvider)
            .submitReel(
              reel,
              submittedByUid: user.id,
              localVideoPath: usingLocalFile && Env.firebaseConfigured
                  ? _video!.path
                  : null,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reelsSubmitFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.reelsEditYourGame : l10n.reelsShareYourGame,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.reelsGameplayVideoLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _VideoPickerField(video: _video, onPick: _pickVideo),
            if (_isEditing && _video == null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.reelsVideoKeptHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.authOr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoUrl,
              decoration: InputDecoration(
                labelText: l10n.reelsVideoUrlLabel,
                hintText: l10n.reelsVideoUrlHint,
              ),
              keyboardType: TextInputType.url,
              validator: _validateOptionalUrl,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.reelsGameNameLabel),
              validator: _requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caption,
              decoration: InputDecoration(
                labelText: l10n.reelsShortDescriptionLabel,
                hintText: l10n.reelsShortDescriptionHint,
              ),
              maxLines: 3,
              validator: _requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tags,
              decoration: InputDecoration(
                labelText: l10n.reelsTagsLabel,
                hintText: '#döngü #labirent',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gameUrl,
              decoration: InputDecoration(
                labelText: l10n.reelsGameLinkLabel,
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
              validator: _validateUrl,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? l10n.actionUpdate : l10n.actionPublish),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video seçme alanı — henüz seçim yoksa "seç" kartı, seçiliyse dosya
/// adını ve değiştirme imkanını gösterir. Önizleme oynatmıyor (yalnızca
/// dosya seçildiğini teyit eder) — akıştaki gerçek oynatma [ReelPage]'de.
class _VideoPickerField extends StatelessWidget {
  const _VideoPickerField({required this.video, required this.onPick});
  final XFile? video;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  video == null
                      ? Icons.video_call_outlined
                      : Icons.videocam_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  video == null ? l10n.reelsPickVideoPrompt : video!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                video == null ? l10n.reelsPickAction : l10n.reelsChangeAction,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
