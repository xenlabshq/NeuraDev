// Placeholder test — flutter test komutunun temiz çalıştığını doğrular.
// Gerçek overflow tarama daha sonra flutter_runner_pro ile yapılacak.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: smoke test for flutter test pipeline',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Text('Hello')),
    ));
    expect(find.text('Hello'), findsOneWidget);
  });
}