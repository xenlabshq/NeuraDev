import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/home_shell.dart' show LessonOverlayScope;
import '../../../../app/theme/colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';
import '../utils/news_labels.dart';

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
  LessonOverlayScope? _overlayScope;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Shell altındaki floating tab bar'ı gizle — aksi halde
    // Kaydet/Yayınla düğmesi barın altında kalıyordu.
    _overlayScope = LessonOverlayScope(context);
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
    _overlayScope?.dispose();
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.newsSaveFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(BuildContext context, String? v) =>
      (v == null || v.trim().isEmpty)
      ? AppLocalizations.of(context).fieldRequired
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.newsEditTitle : l10n.newsNewTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.newsFieldTitle),
              validator: (v) => _required(context, v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summary,
              decoration: InputDecoration(labelText: l10n.newsFieldSummary),
              maxLines: 2,
              validator: (v) => _required(context, v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              decoration: InputDecoration(labelText: l10n.newsFieldBody),
              maxLines: 6,
              validator: (v) => _required(context, v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _source,
              decoration: InputDecoration(labelText: l10n.newsFieldSource),
              validator: (v) => _required(context, v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceUrl,
              decoration: InputDecoration(
                labelText: l10n.newsFieldSourceUrl,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrl,
              decoration: InputDecoration(
                labelText: l10n.newsFieldImageUrl,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<NewsCategory>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.newsFieldCategory),
              items: NewsCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.localizedLabel(l10n)}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<NewsPriority>(
              initialValue: _priority,
              decoration: InputDecoration(labelText: l10n.newsFieldPriority),
              items: NewsPriority.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.localizedLabel(l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.newsFieldBreaking),
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
                    : Text(_isEditing ? l10n.actionUpdate : l10n.actionPublish),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
