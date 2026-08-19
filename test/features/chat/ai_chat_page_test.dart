import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/chat/presentation/pages/ai_chat_page.dart';

Widget _wrap() => const ProviderScope(
  child: MaterialApp(home: AiChatPage()),
);

Future<void> _sendMessage(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byIcon(Icons.send_rounded));
  await tester.pump();
  // _generateResponse'un 1200ms gecikmesini bekle.
  await tester.pump(const Duration(milliseconds: 1300));
}

void main() {
  testWidgets('shows the welcome message on first open', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Neuroup AI asistanınım'), findsOneWidget);
  });

  testWidgets('greeting keywords get the greeting response', (tester) async {
    await tester.pumpWidget(_wrap());
    await _sendMessage(tester, 'merhaba');
    expect(
      find.textContaining('Sana nasıl yardımcı olabilirim'),
      findsOneWidget,
    );
  });

  testWidgets('"seviye" asks return the tier explanation', (tester) async {
    await tester.pumpWidget(_wrap());
    await _sendMessage(tester, 'seviye sistemi nedir?');
    expect(find.textContaining('5 tier var'), findsOneWidget);
  });

  testWidgets('"rozet" asks return the badge explanation', (tester) async {
    await tester.pumpWidget(_wrap());
    await _sendMessage(tester, 'rozet nasıl kazanılır?');
    expect(find.textContaining('8 farklı rozet var'), findsOneWidget);
  });

  testWidgets('an unmatched question gets the fallback response', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _sendMessage(tester, 'kuantum fiziği hakkında ne düşünüyorsun');
    expect(find.textContaining('İlginç bir soru!'), findsOneWidget);
  });

  testWidgets('sending an empty message does nothing', (tester) async {
    await tester.pumpWidget(_wrap());
    final before = find.byType(ListView).evaluate().isNotEmpty;
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    // Sadece ilk karşılama mesajı olmalı, kullanıcı balonu eklenmemiş olmalı.
    expect(find.textContaining('Neuroup AI asistanınım'), findsOneWidget);
    expect(before, isTrue);
  });

  testWidgets('tapping a quick prompt sends that question', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Nasıl rozet kazanırım?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.textContaining('8 farklı rozet var'), findsOneWidget);
  });
}
