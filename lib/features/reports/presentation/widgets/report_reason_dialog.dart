import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Şikayet sebebi giriş diyaloğu.
///
/// KASITLI OLARAK kendi `TextEditingController`'ını sahiplenen düzgün bir
/// `StatefulWidget` — daha önce controller, diyaloğu açan fonksiyonda
/// manuel bir yerel değişken olarak oluşturulup `showDialog` kapandıktan
/// hemen sonra elle `dispose()` ediliyordu. Bu, controller'ı kullanan
/// `TextField`in element'i framework tarafından unmount edilirken
/// (dialog route'unun kendi kapanış animasyonu/dispose sırasıyla
/// çakışarak) "'_dependents.isEmpty' is not true" assertion'ı ile
/// gerçek cihazlarda çökmeye yol açıyordu — controller'ı kendi
/// `State.dispose()`'unda temizlemek framework'ün beklediği doğru
/// yaşam döngüsü.
class ReportReasonDialog extends StatefulWidget {
  const ReportReasonDialog({required this.title, super.key});
  final String title;

  @override
  State<ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<ReportReasonDialog> {
  final _reasonCtl = TextEditingController();

  @override
  void dispose() {
    _reasonCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _reasonCtl,
        autofocus: true,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: l10n.reelsReportReasonHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionGiveUp),
        ),
        FilledButton(
          onPressed: _reasonCtl.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_reasonCtl.text.trim()),
          child: Text(l10n.reelsReportAction),
        ),
      ],
    );
  }
}
