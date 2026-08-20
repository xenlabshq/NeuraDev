import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';

/// Admin/moderatör için haber ekleme-düzenleme formu.
///
/// [existing] verilirse düzenleme modunda açılır (tüm alanlar
/// önceden doldurulur, kaydet güncelleme yapar); null ise yeni haber
/// oluşturma modunda açılır.
class NewsFormPage extends ConsumerStatefulWidget {
  const NewsFormPage({this.existing, super.key});
  final NewsArticle? existing;

  @override
  ConsumerState<NewsFormPage> createState() => _NewsFormPageState();
}

class _NewsFormPageState extends ConsumerState<NewsFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _body;
  late final TextEditingController _source;
  late final TextEditingController _sourceUrl;
  late final TextEditingController _imageUrl;
  late NewsCategory _category;
  late NewsPriority _priority;
  late bool _isBreaking;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _title = TextEditingController(text: a?.title ?? '');
    _summary = TextEditingController(text: a?.summary ?? '');
    _body = TextEditingController(text: a?.body ?? '');
    _source = TextEditingController(text: a?.source ?? '');
    _sourceUrl = TextEditingController(text: a?.sourceUrl ?? '');
    _imageUrl = TextEditingController(text: a?.imageUrl ?? '');
    _category = a?.category ?? NewsCategory.education;
    _priority = a?.priority ?? NewsPriority.normal;
    _isBreaking = a?.isBreaking ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    _source.dispose();
    _sourceUrl.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(newsRepositoryProvider);
    final article = NewsArticle(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      summary: _summary.text.trim(),
      body: _body.text.trim(),
      source: _source.text.trim(),
      sourceUrl: _sourceUrl.text.trim(),
      category: _category,
      publishedAt: widget.existing?.publishedAt ?? DateTime.now(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      isBreaking: _isBreaking,
      priority: _priority,
    );
    try {
      if (_isEditing) {
        await repo.updateArticle(article);
      } else {
        await repo.createArticle(article);
      }
      ref.invalidate(newsStreamProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bu alan gerekli' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Haberi Düzenle' : 'Yeni Haber'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Başlık'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summary,
              decoration: const InputDecoration(labelText: 'Özet'),
              maxLines: 2,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'İçerik'),
              maxLines: 6,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _source,
              decoration: const InputDecoration(labelText: 'Kaynak'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceUrl,
              decoration: const InputDecoration(
                labelText: 'Kaynak linki (opsiyonel)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                labelText: 'Görsel linki (opsiyonel)',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<NewsCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: NewsCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.label}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<NewsPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Önem derecesi'),
              items: NewsPriority.values
                  .map(
                    (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Son dakika'),
              value: _isBreaking,
              onChanged: (v) => setState(() => _isBreaking = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
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
                    : Text(_isEditing ? 'Güncelle' : 'Yayınla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
