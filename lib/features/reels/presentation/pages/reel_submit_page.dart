import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/entities/game_reel.dart';
import '../providers/reels_providers.dart';

/// Kullanıcının kendi oyununu (başlık + tanıtım + oyun linki) Reels
/// akışına eklemesini sağlayan form. Herhangi bir giriş yapmış kullanıcı
/// erişebilir — staff-only değil, çünkü bu bir moderasyon aracı değil,
/// normal kullanıcı içerik gönderim akışı.
class ReelSubmitPage extends ConsumerStatefulWidget {
  const ReelSubmitPage({super.key});

  @override
  ConsumerState<ReelSubmitPage> createState() => _ReelSubmitPageState();
}

class _ReelSubmitPageState extends ConsumerState<ReelSubmitPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _caption = TextEditingController();
  final _tags = TextEditingController();
  final _gameUrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    _tags.dispose();
    _gameUrl.dispose();
    super.dispose();
  }

  String? _requiredField(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bu alan gerekli' : null;

  String? _validateUrl(String? v) {
    final required = _requiredField(v);
    if (required != null) return required;
    final uri = Uri.tryParse(v!.trim());
    if (uri == null || !(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) {
      return 'Geçerli bir link gir (https://...)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentAuthUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısın')),
      );
      return;
    }
    setState(() => _saving = true);
    final accents = ReelAccent.values;
    final accent = accents[Random().nextInt(accents.length)];
    final tag = user.displayName.trim().isEmpty
        ? '@kullanici'
        : '@${user.displayName.trim().toLowerCase().replaceAll(' ', '')}';
    final reel = GameReel(
      id: '',
      devName: user.displayName.trim().isEmpty
          ? 'Kullanıcı'
          : user.displayName.trim(),
      devTag: tag,
      title: _title.text.trim(),
      caption: _caption.text.trim(),
      tags: _tags.text.trim(),
      accent: accent,
      symbols: const ['🎮', '▶', 'GO'],
      hud: 'Topluluk · Yeni',
      likes: 0,
      gameUrl: _gameUrl.text.trim(),
      comments: const [],
    );
    try {
      await ref
          .read(reelSubmissionRepositoryProvider)
          .submitReel(reel, submittedByUid: user.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gönderilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyununu Paylaş')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Oyun adı'),
              validator: _requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caption,
              decoration: const InputDecoration(
                labelText: 'Kısa tanıtım',
                hintText: 'Oyununu bir-iki cümlede anlat',
              ),
              maxLines: 3,
              validator: _requiredField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Etiketler (opsiyonel)',
                hintText: '#döngü #labirent',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gameUrl,
              decoration: const InputDecoration(
                labelText: 'Oyun linki',
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
                    : const Text('Paylaş'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
