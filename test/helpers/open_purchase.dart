import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openPurchaseFromProduct(WidgetTester tester) async {
  await tester.tap(find.text('Leche entera'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Anotar compra'),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Anotar compra'));
  await tester.pumpAndSettle();
}
