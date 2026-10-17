import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main.dart';
import 'package:gestion_inventario/screens/pantalla_registrar_compra.dart';

void main() {
  testWidgets('Nuevo artículo se abre desde Inicio y se adapta al celular', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.tap(find.byTooltip('Agregar artículo'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo artículo'), findsOneWidget);
      expect(find.text('Foto opcional'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // El margen permite desplazar el formulario sin arrastrar campos internos.
      for (var step = 0; step < 5; step++) {
        await tester.dragFrom(const Offset(10, 650), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Guardar artículo'), findsOneWidget);
      expect(find.text('Congelador'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Alacena'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Registrar compra carga y no tiene los tres puntos en la barra superior', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPurchaseScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Comprobar que los tres puntos fueron removidos
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
