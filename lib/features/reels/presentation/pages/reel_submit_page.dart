import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/home_shell.dart' show LessonOverlayScope;
import '../../../../app/theme/colors.dart';
import '../../../../core/env/env.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../data/reel_submission_repository_impl.dart' show reelUploadCooldown;
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
  bool _saving = false;
  XFile? _media;
  late ReelMediaType _mediaType;
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
    _mediaType = e?.mediaType ?? ReelMediaType.video;
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
    _overlayScope?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = _mediaType == ReelMediaType.video
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _media = picked);
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
    // Düzenlerken medya zorunlu değil — mevcut medya korunur, sadece
    // değiştirmek isteyen kullanıcı yeniden seçebilir. Yeni gönderimde
    // bir dosya (video ya da resim) seçilmiş olmalı.
    if (!_isEditing && _media == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reelsPickMediaFirst)),
      );
      return;
    }
    final repo = ref.read(reelSubmissionRepositoryProvider);
    if (!_isEditing) {
      // Storage maliyetini kontrol altında tutmak için kullanıcı başına
      // günde bir yükleme hakkı var — firestore.rules bunu sunucu
      // tarafında da zorunlu kılar, burası sadece kullanıcıya erken ve
      // anlaşılır bir mesaj göstermek için.
      final last = await repo.lastUploadAt(user.id);
      if (last != null) {
        final remaining = reelUploadCooldown - DateTime.now().difference(last);
        if (remaining > Duration.zero) {
          if (!mounted) return;
          final hours = remaining.inHours;
          final minutes = remaining.inMinutes.remainder(60);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reelsDailyLimitReached(hours, minutes)),
            ),
          );
          return;
        }
      }
    }
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final existing = widget.existing!;
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
          videoUrl: existing.videoUrl,
          mediaType: _mediaType,
          uploaderId: existing.uploaderId,
          comments: existing.comments,
        );
        await repo.updateReel(updated, localMediaPath: _media?.path);
      } else {
        final accents = ReelAccent.values;
        final accent = accents[Random().nextInt(accents.length)];
        final tag = user.displayName.trim().isEmpty
            ? '@${l10n.reelsFallbackUserTag}'
            : '@${user.displayName.trim().toLowerCase().replaceAll(' ', '')}';
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
          // Demo modda (Storage yok) yerel dosya yolu doğrudan videoUrl'e
          // yazılır; gerçek modda repository dosyayı Storage'a yükleyip
          // indirme linkiyle değiştirir (bkz. localMediaPath).
          videoUrl: Env.firebaseConfigured ? null : _media!.path,
          mediaType: _mediaType,
          uploaderId: user.id,
          comments: const [],
        );
        await repo.submitReel(
          reel,
          submittedByUid: user.id,
          localMediaPath: Env.firebaseConfigured ? _media!.path : null,
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
              l10n.reelsMediaLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReelMediaType>(
              segments: [
                ButtonSegment(
                  value: ReelMediaType.video,
                  label: Text(l10n.reelsMediaTypeVideo),
                  icon: const Icon(Icons.videocam_rounded),
                ),
                ButtonSegment(
                  value: ReelMediaType.image,
                  label: Text(l10n.reelsMediaTypeImage),
                  icon: const Icon(Icons.image_rounded),
                ),
              ],
              selected: {_mediaType},
              onSelectionChanged: (selection) => setState(() {
                _mediaType = selection.first;
                _media = null;
              }),
            ),
            const SizedBox(height: 12),
            _MediaPickerField(
              media: _media,
              mediaType: _mediaType,
              onPick: _pickMedia,
            ),
            if (_isEditing && _media == null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.reelsMediaKeptHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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

/// Medya seçme alanı — henüz seçim yoksa "seç" kartı, seçiliyse dosya
/// adını ve değiştirme imkanını gösterir. Önizleme oynatmıyor (yalnızca
/// dosya seçildiğini teyit eder) — akıştaki gerçek oynatma [ReelPage]'de.
class _MediaPickerField extends StatelessWidget {
  const _MediaPickerField({
    required this.media,
    required this.mediaType,
    required this.onPick,
  });
  final XFile? media;
  final ReelMediaType mediaType;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVideo = mediaType == ReelMediaType.video;
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
                  media != null
                      ? (isVideo ? Icons.videocam_rounded : Icons.image_rounded)
                      : (isVideo
                            ? Icons.video_call_outlined
                            : Icons.add_photo_alternate_outlined),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  media == null
                      ? (isVideo
                            ? l10n.reelsPickVideoPrompt
                            : l10n.reelsPickImagePrompt)
                      : media!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                media == null ? l10n.reelsPickAction : l10n.reelsChangeAction,
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
