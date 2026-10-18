import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/presentation/modelos_vista_calendario.dart';
import 'package:gestion_inventario/screens/pantalla_alertas_dia.dart';
import 'package:gestion_inventario/screens/pantalla_tiendas.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';

import 'purchase_flow_test.dart' show PurchaseDatabase;

void phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Tiendas permite cambiar de filtro y desactivarlo para verlas todas',
    (tester) async {
      phone(tester);
      final db = PurchaseDatabase();
      db.tables['Tienda']!.first.addAll({
        'nombre': 'Sin compras',
        'total_compras': 0,
      });
      db.tables['Tienda']!.addAll([
        {
          'id': 2,
          'nombre': 'Con una compra',
          'tipo_tienda_id': 1,
          'total_compras': 1,
        },
        {
          'id': 3,
          'nombre': 'Compra habitual',
          'tipo_tienda_id': 1,
          'total_compras': 3,
        },
      ]);
      final inventory = InventarioDB.conDatabase(db);
      await tester.pumpWidget(const MaterialApp(home: StoresScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Todas'), findsNothing);
      expect(find.text('Sin compras'), findsOneWidget);
      expect(find.text('Con una compra'), findsOneWidget);
      expect(find.text('Compra habitual'), findsOneWidget);
      Future<void> tapFilter(String label) async {
        final filter = find.widgetWithText(OutlinedButton, label);
        await Scrollable.ensureVisible(tester.element(filter), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(filter);
        await tester.pumpAndSettle();
      }

      await tapFilter('Con compras registradas');
      expect(find.text('Sin compras'), findsNothing);
      expect(find.text('Con una compra'), findsOneWidget);
      await tapFilter('Frecuentes');
      expect(find.text('Con una compra'), findsNothing);
      expect(find.text('Compra habitual'), findsOneWidget);
      await tapFilter('Con compras registradas');
      expect(find.text('Con una compra'), findsOneWidget);
      await tapFilter('Con compras registradas');
      expect(find.text('Sin compras'), findsOneWidget);
      expect(find.text('Con una compra'), findsOneWidget);
      await tapFilter('Frecuentes');
      await tapFilter('Frecuentes');
      expect(find.text('Sin compras'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );

  testWidgets(
    'Día permite un único filtro y al quitarlo restaura todos los productos',
    (tester) async {
      phone(tester);
      const alerts = [
        CalendarAlertPreview(
          'Producto vencido',
          'Bolsa de 50 g',
          '1 bolsa de 50 g',
          CalendarPreviewStatus.expired,
          ProductThumbnailKind.placeholder,
        ),
        CalendarAlertPreview(
          'Producto próximo',
          'Bolsa de 50 g',
          '1 bolsa de 50 g',
          CalendarPreviewStatus.expiring,
          ProductThumbnailKind.placeholder,
        ),
        CalendarAlertPreview(
          'Producto sin alerta',
          'Bolsa de 50 g',
          '1 bolsa de 50 g',
          CalendarPreviewStatus.healthy,
          ProductThumbnailKind.placeholder,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: DayAlertsScreen(day: DateTime(2030), alerts: alerts),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Todos'), findsNothing);
      expect(find.text('Producto vencido'), findsOneWidget);
      expect(find.text('Producto próximo'), findsOneWidget);
      expect(find.text('Producto sin alerta'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      for (final label in ['Caducado', 'Por caducar', 'Por agotarse']) {
        expect(find.textContaining(label), findsNothing);
      }
      await tester.tap(find.text('Sin alerta (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Producto próximo'), findsNothing);
      expect(find.text('Producto sin alerta'), findsOneWidget);
      await tester.tap(find.text('Sin alerta (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Producto vencido'), findsOneWidget);
      expect(find.text('Producto próximo'), findsOneWidget);
      await tester.tap(find.text('Con alertas (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Producto sin alerta'), findsNothing);
      await tester.tap(find.text('Con alertas (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Producto sin alerta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
