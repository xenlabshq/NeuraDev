import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../data/python_simulator.dart';
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

  @override
  void initState() {
    super.initState();
    final island = ref
        .read(islandsProvider)
        .firstWhere((i) => i.id == widget.islandId);
    final node = island.nodes.firstWhere((n) => n.id == widget.nodeId);
    _code = TextEditingController(text: node.starterCode);
    _editorScroll = ScrollController();
  }

  @override
  void dispose() {
    _code.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  void _run() {
    setState(() {
      _running = true;
      _error = null;
      _success = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final result = _simulator.run(_code.text);
      setState(() {
        _output = result.output;
        _error = result.errors.isEmpty ? null : result.errors.join('\n');
        _running = false;
        if (result.success) {
          final node = ref
              .read(islandsProvider)
              .firstWhere((i) => i.id == widget.islandId)
              .nodes
              .firstWhere((n) => n.id == widget.nodeId);
          _success = result.combinedOutput.trim() == node.expectedOutput.trim();
        }
      });
    });
  }

  void _showSolution() {
    final island = ref
        .read(islandsProvider)
        .firstWhere((i) => i.id == widget.islandId);
    final node = island.nodes.firstWhere((n) => n.id == widget.nodeId);
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
    final island = ref
        .read(islandsProvider)
        .firstWhere((i) => i.id == widget.islandId);
    final node = island.nodes.firstWhere((n) => n.id == widget.nodeId);
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
    final island = ref
        .read(islandsProvider)
        .firstWhere((i) => i.id == widget.islandId);
    final node = island.nodes.firstWhere((n) => n.id == widget.nodeId);
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
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        final count = '\n'.allMatches(value.text).length + 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 1; i <= count; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$i',
                  style: const TextStyle(
                    color: Color(0xFF858585),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
          ],
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
  });

  final List<String> output;
  final String? error;
  final bool running;
  final bool success;
  final String expected;

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
