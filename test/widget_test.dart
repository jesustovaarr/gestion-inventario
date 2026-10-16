import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_inventario/main.dart' as app;

void main() {
  testWidgets('La entrada principal abre Alacena', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Alacena'), findsOneWidget);
    expect(find.text('Leche entera'), findsOneWidget);
  });
}
