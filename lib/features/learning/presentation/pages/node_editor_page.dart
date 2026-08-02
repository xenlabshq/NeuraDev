import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide ErrorHint;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../data/python_simulator.dart';
import '../../domain/entities/error_hint.dart';
import '../../domain/entities/learning_island.dart';
import '../providers/adaptive_providers.dart';
import '../providers/learning_providers.dart';

class NodeEditorPage extends ConsumerStatefulWidget {
  const NodeEditorPage({
    required this.islandId,
    required this.nodeId,
    super.key,
  });
  final String islandId;
  final String nodeId;

  @override
  ConsumerState<NodeEditorPage> createState() => _NodeEditorPageState();
}

class _NodeEditorPageState extends ConsumerState<NodeEditorPage> {
  late final TextEditingController _code;
  late final ScrollController _editorScroll;
  final _simulator = PythonSimulator();
  List<String> _output = const [];
  String? _error;
  bool _running = false;
  bool _success = false;
  bool _showTutorial = true;
  ErrorHint? _hint;

  /// Aktif ada ve node'u tek seferde arar; bulunamazsa null döner.
  /// F-19: Artık `StateError` riski yok.
  (LearningIsland?, LearningNode?) _findActive() {
    final island = ref
        .read(islandsProvider)
        .firstWhereOrNull((i) => i.id == widget.islandId);
    final node = island?.nodes
        .firstWhereOrNull((n) => n.id == widget.nodeId);
    return (island, node);
  }

  @override
  void initState() {
    super.initState();
    final (_, node) = _findActive();
    _code = TextEditingController(text: node?.starterCode ?? '');
    _editorScroll = ScrollController();
  }

  @override
  void dispose() {
    _code.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  DateTime? _runStartTime;
  int _sessionAttempts = 0;

  void _run() {
    if (_runStartTime == null) _runStartTime = DateTime.now();
    _sessionAttempts++;
    setState(() {
      _running = true;
      _error = null;
      _success = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // Beklenen çıktıyı simülatöre geçir → akıllı hata analizi için.
      final (island, node) = _findActive();
      if (island == null || node == null) {
        setState(() {
          _running = false;
          _error = 'Ders bulunamadı (id: ${widget.islandId}/${widget.nodeId}).';
        });
        return;
      }
      final result = _simulator.run(
        _code.text,
        expectedOutput: node.expectedOutput,
      );
      final timeMs = _runStartTime != null
          ? DateTime.now().difference(_runStartTime!).inMilliseconds
          : 0;

      final isCorrect = result.success &&
          result.combinedOutput.trim() == node.expectedOutput.trim();

      setState(() {
        _output = result.output;
        _error = result.errors.isEmpty ? null : result.errors.join('\n');
        _running = false;
        _success = isCorrect;
        _hint = result.hint; // akıllı ipucu
      });

      // Adaptive engine'e deneme kaydı.
      ref.read(adaptiveMemoryProvider.notifier).recordAttempt(
            widget.nodeId,
            success: result.success && isCorrect,
            attemptsInSession: _sessionAttempts,
            difficulty: _inferDifficulty(),
            timeMs: timeMs,
          );
    });
  }

  /// Kullanıcının zorluk algısını çıktıdan çıkar.
  /// Çok deneme yaptıysa zorlanmış demektir.
  double _inferDifficulty() {
    if (_sessionAttempts == 0) return 0.5;
    // 1. denemede yaptıysa kolay, 5+ denemede yaptıysa zor
    return (_sessionAttempts / 5.0).clamp(0.0, 1.0);
  }

  void _showSolution() {
    final (_, node) = _findActive();
    if (node == null) return;
    setState(() {
      _code.text = node.solution;
    });
  }

  void _verify() {
    if (!_success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce kodu çalıştır ve doğru çıktıyı al!'),
        ),
      );
      return;
    }
    final (island, node) = _findActive();
    if (island == null || node == null) return;
    ref.read(learningProgressProvider.notifier).markNodeCompleted(
          widget.nodeId,
          xpEarned: node.points,
        );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _SuccessDialog(
        xp: node.points,
        onContinue: () {
          Navigator.of(dialogCtx).pop(); // dialog'u kapat
        },
      ),
    ).then((_) {
      // Dialog kapandıktan sonra editor'ı da kapat.
      // dialogCtx artık defunct olabilir, bu yüzden State's context'ini kullan.
      if (!mounted) return;
      Navigator.of(context).pop(); // editor'ı kapat → detail_page'e dön
    });
  }



  @override
  Widget build(BuildContext context) {
    final (island, node) = _findActive();
    if (island == null || node == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ders bulunamadı')),
        body: Center(
          child: Text(
            'Ders yüklenemedi (id: ${widget.islandId}/${widget.nodeId}).',
          ),
        ),
      );
    }
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: island.color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(node.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showTutorial
                ? Icons.menu_book_rounded
                : Icons.menu_book_outlined),
            tooltip: 'Eğitimi göster',
            onPressed: () => setState(() => _showTutorial = !_showTutorial),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showTutorial)
            _TutorialPanel(
              tutorial: node.tutorial,
              onClose: () => setState(() => _showTutorial = false),
            ),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _CodeEditor(
                          controller: _code,
                          scrollController: _editorScroll,
                          islandColor: island.color,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _OutputPanel(
                          output: _output,
                          error: _error,
                          running: _running,
                          success: _success,
                          expected: node.expectedOutput,
                          hint: _hint,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _CodeEditor(
                          controller: _code,
                          scrollController: _editorScroll,
                          islandColor: island.color,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _OutputPanel(
                          output: _output,
                          error: _error,
                          running: _running,
                          success: _success,
                          expected: node.expectedOutput,
                          hint: _hint,
                        ),
                      ),
                    ],
                  ),
          ),
          _ActionBar(
            onRun: _run,
            onShowSolution: _showSolution,
            onVerify: _verify,
            running: _running,
            success: _success,
            points: node.points,
          ),
        ],
      ),
    );
  }
}

class _TutorialPanel extends StatelessWidget {
  const _TutorialPanel({required this.tutorial, required this.onClose});
  final String tutorial;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              const Text(
                'EĞİTİM',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 18),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tutorial,
            style: const TextStyle(
              color: Color(0xFFD4D4D4),
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeEditor extends StatelessWidget {
  const _CodeEditor({
    required this.controller,
    required this.scrollController,
    required this.islandColor,
  });
  final TextEditingController controller;
  final ScrollController scrollController;
  final Color islandColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Satır numaraları
              Container(
                width: 44,
                color: const Color(0xFF252526),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _LineNumbers(controller: controller),
              ),
              // Editör
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    minLines: 8,
                    style: const TextStyle(
                      color: Color(0xFFD4D4D4),
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '# Python kodunu buraya yaz...',
                      hintStyle: TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontFamily: 'monospace',
                      ),
                    ),
                    cursorColor: islandColor,
                  ),
                ),
              ),
            ],
          ),
          // Sağ üst köşede dosya adı
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: islandColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'main.py',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineNumbers extends StatelessWidget {
  const _LineNumbers({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // F-15: Column + for-loop yerine sabit genişlikli ListView.builder.
    // Her tuş vuruşunda tüm satırlar için widget instantiate etmek
    // yerine sadece scroll'a giren satırlar oluşturulur.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        final count = '\n'.allMatches(value.text).length + 1;
        // Maks satır sayısı — sanal listeleme. Aşırı büyük olmasın.
        const maxLines = 9999;
        final itemCount = count.clamp(1, maxLines);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: itemCount,
          itemExtent: 19.5, // 13px font * 1.5 height
          itemBuilder: (_, i) {
            return SizedBox(
              height: 19.5,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Color(0xFF858585),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OutputPanel extends StatelessWidget {
  const _OutputPanel({
    required this.output,
    required this.error,
    required this.running,
    required this.success,
    required this.expected,
    this.hint,
  });

  final List<String> output;
  final String? error;
  final bool running;
  final bool success;
  final String expected;
  final ErrorHint? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E0E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: success
                        ? AppColors.success
                        : (error != null
                            ? AppColors.error
                            : (running
                                ? AppColors.warning
                                : AppColors.textTertiary)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ÇIKTI',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (success)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            color: AppColors.success, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'DOĞRU',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (running)
                    const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.warning,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Çalışıyor...',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    )
                  else if (output.isEmpty)
                    const Text(
                      'Kodu çalıştırmak için ▶ butonuna bas.',
                      style: TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      output.join('\n'),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  // Akıllı öğretmen ipucu kartı — hata veya yanlış çıktı varsa.
                  if (hint != null) ...[
                    const SizedBox(height: 16),
                    _ErrorHintCard(hint: hint),
                  ],
                  if (output.isNotEmpty && !success) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.flag_rounded,
                                  color: AppColors.info, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'BEKLENEN ÇIKTI',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expected,
                            style: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontFamily: 'monospace',
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onRun,
    required this.onShowSolution,
    required this.onVerify,
    required this.running,
    required this.success,
    required this.points,
  });
  final VoidCallback onRun;
  final VoidCallback onShowSolution;
  final VoidCallback onVerify;
  final bool running;
  final bool success;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCCCCCC),
                  side: const BorderSide(color: Color(0xFF3E3E3E)),
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onShowSolution,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                label: const Text(
                  'Çözüm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2EA043),
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: running ? null : onRun,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text(
                  'Çalıştır',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: success
                      ? AppColors.gold
                      : Colors.grey.shade700,
                  foregroundColor:
                      success ? Colors.white : Colors.grey.shade400,
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: success ? onVerify : null,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  '+$points XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.xp, required this.onContinue});
  final int xp;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.success, Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Tebrikler!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$xp XP kazandın!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                minimumSize: const Size(160, 48),
              ),
              onPressed: onContinue,
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Akıllı öğretmen ipucu kartı. Hata türüne göre renk + emoji + mesaj + örnek.
class _ErrorHintCard extends StatefulWidget {
  const _ErrorHintCard({required this.hint});
  final ErrorHint? hint;

  @override
  State<_ErrorHintCard> createState() => _ErrorHintCardState();
}

class _ErrorHintCardState extends State<_ErrorHintCard> {
  bool _expanded = true;

  Color _bgFor(ErrorKind k) => switch (k) {
        ErrorKind.syntax => const Color(0xFF3A1A1F),
        ErrorKind.name => const Color(0xFF3A2A1A),
        ErrorKind.type => const Color(0xFF2A1A3A),
        ErrorKind.outOfBounds => const Color(0xFF3A2A1F),
        ErrorKind.logic => const Color(0xFF3A361A),
        ErrorKind.timeout => const Color(0xFF1A2A3A),
        ErrorKind.zeroDivision => const Color(0xFF3A1A2A),
        ErrorKind.empty => const Color(0xFF2A2A2A),
        ErrorKind.unknown => const Color(0xFF2A2A2A),
      };

  Color _borderFor(ErrorKind k) => switch (k) {
        ErrorKind.syntax => const Color(0xFFEF4444),
        ErrorKind.name => const Color(0xFFF59E0B),
        ErrorKind.type => const Color(0xFFA855F7),
        ErrorKind.outOfBounds => const Color(0xFFB45309),
        ErrorKind.logic => const Color(0xFFEAB308),
        ErrorKind.timeout => const Color(0xFF3B82F6),
        ErrorKind.zeroDivision => const Color(0xFFEC4899),
        ErrorKind.empty => const Color(0xFF6B7280),
        ErrorKind.unknown => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final h = widget.hint;
    if (h == null) return const SizedBox.shrink();
    final color = _borderFor(h.kind);
    final bg = _bgFor(h.kind);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Text(h.kind.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 ${h.title}',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (h.lineHint != null)
                          Text(
                            'Yaklaşık satır: ${h.lineHint}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white60,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.message,
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (h.example != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        h.example!,
                        style: const TextStyle(
                          color: Color(0xFFB8E986),
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
