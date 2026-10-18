import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/daos/producto_dao.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';
import 'package:gestion_inventario/widgets/campos_presentacion_producto.dart';
import 'package:gestion_inventario/widgets/editor_lotes_producto.dart';

import 'product_editing_test.dart' show EditingDatabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Presentación se elige antes de unidad y contenido, sin desplegar otra sección',
    (tester) async {
      var packaging = PresentacionCompra.pieza;
      var unit = 'pza';
      final content = TextEditingController(text: '50');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ProductPresentationFields(
                packaging: packaging,
                unit: unit,
                contentController: content,
                onPackagingChanged: (p) => setState(() => packaging = p),
                onUnitChanged: (u) => setState(() => unit = u),
                onContentChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      final dropdown = find.byType(DropdownButtonFormField<PresentacionCompra>);
      expect(
        tester.getTopLeft(dropdown).dy,
        lessThan(tester.getTopLeft(find.text('Unidad de medida')).dy),
      );
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      for (final p in PresentacionCompra.values) {
        expect(find.text(p.singular), findsWidgets);
      }
      await tester.tap(find.text('Bolsa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('g'));
      await tester.pumpAndSettle();
      expect(packaging, PresentacionCompra.bolsa);
      expect(unit, 'g');
      expect(find.text('Contenido por bolsa'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('catalog-package-content')),
            )
            .controller!
            .text,
        '50',
      );
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('A granel').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('catalog-package-content')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      content.dispose();
    },
  );

  testWidgets(
    'X confirma y retira solo el lote elegido; los nuevos eliminados no se guardan',
    (tester) async {
      List<Lote>? changes;
      const lots = [
        Lote(id: 1, productoId: 1, cantidad: 100, fechaCaducidad: '2030-01-01'),
        Lote(id: 2, productoId: 1, cantidad: 200, fechaCaducidad: '2030-02-01'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductLotsEditor(
                productoId: 1,
                lotes: lots,
                unit: 'g',
                defaultPackaging: PresentacionCompra.bolsa,
                defaultContent: 50,
                onChanged: (value) => changes = value,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Eliminar lote #1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Lote #1'), findsOneWidget);
      expect(changes, isNull);
      await tester.tap(find.byTooltip('Eliminar lote #1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Lote #1'), findsNothing);
      expect(find.text('Lote #2'), findsOneWidget);
      expect(changes!.singleWhere((l) => l.id == 1).cantidad, 0);
      expect(changes!.singleWhere((l) => l.id == 2).cantidad, 200);
      final quantity = find.byType(TextFormField);
      await tester.enterText(quantity, '150');
      await tester.pumpAndSettle();
      expect(find.text('3 bolsas de 50 g'), findsOneWidget);
      await tester.ensureVisible(find.text('Agregar lote'));
      await tester.tap(find.text('Agregar lote'));
      await tester.pumpAndSettle();
      expect(changes!.where((l) => l.id == null), hasLength(1));
      await tester.ensureVisible(find.byTooltip('Eliminar lote nuevo'));
      await tester.tap(find.byTooltip('Eliminar lote nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(changes!.where((l) => l.id == null), isEmpty);
      expect(changes!.singleWhere((l) => l.id == 2).cantidad, 150);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Quitar un lote solo cambia existencias al guardar y conserva el historial',
    (tester) async {
      final db = EditingDatabase();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      final product = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
      final historyBefore = Map.of(db.tables['Movimiento_Inventario']!.single);
      await tester.pumpWidget(
        MaterialApp(home: ProductFormScreen(product: product)),
      );
      await tester.pumpAndSettle();
      final close = find.byTooltip('Eliminar lote #1');
      await tester.scrollUntilVisible(
        close,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(close), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(close);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('No hay lotes con existencias.'), findsOneWidget);
      expect(db.tables['Lote']!.single['cantidad'], 2);
      final save = find.text('Guardar cambios');
      await tester.scrollUntilVisible(
        save,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(db.tables['Lote']!.single['cantidad'], 0);
      expect(db.tables['Lote']!.single['alarma_activa'], 0);
      expect(db.tables['Movimiento_Inventario']!.single, historyBefore);
      expect((await ProductoDao(db).obtenerPorId(1))!.stockActual, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
}
