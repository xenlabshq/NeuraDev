import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/shared/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState shows title, message, and CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'Hiç öğe yok',
            message: 'Yeni bir şey ekleyin',
            actionLabel: 'Ekle',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Hiç öğe yok'), findsOneWidget);
    expect(find.text('Yeni bir şey ekleyin'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
    expect(find.text('Ekle'), findsOneWidget);

    await tester.tap(find.text('Ekle'));
    expect(tapped, isTrue);
  });
}
