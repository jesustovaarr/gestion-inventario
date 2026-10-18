import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main.dart';
import 'package:gestion_inventario/screens/pantalla_inicio.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';
import 'package:gestion_inventario/screens/pantalla_alertas_dia.dart';
import 'package:gestion_inventario/presentation/modelos_vista_calendario.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';
import 'package:badges/badges.dart' as badges;
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';

void main() {
  testWidgets('Alacena smoke test carga la aplicación', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlacenaPreviewApp());
    expect(find.byType(AlacenaPreviewApp), findsOneWidget);
  });

  testWidgets(
    'HomeScreen muestra números dinámicos de clasificación y permite filtrar',
    (WidgetTester tester) async {
      final sections = [
        const PantrySectionPreview(
          title: 'Caducados',
          caption: '1 para desechar',
          status: PantryPreviewStatus.expired,
          products: [
            PantryProductPreview(
              name: 'Leche agria',
              category: 'Lácteos',
              status: PantryPreviewStatus.expired,
              note: 'Vencido',
              quantity: '1 L',
              thumbnail: ProductThumbnailKind.milk,
            ),
          ],
        ),
        const PantrySectionPreview(
          title: 'Por caducar',
          caption: '2 en 3 días',
          status: PantryPreviewStatus.expiring,
          products: [
            PantryProductPreview(
              name: 'Yogurt',
              category: 'Lácteos',
              status: PantryPreviewStatus.expiring,
              note: 'Pronto',
              quantity: '1 pza',
              thumbnail: ProductThumbnailKind.yogurt,
            ),
            PantryProductPreview(
              name: 'Queso',
              category: 'Lácteos',
              status: PantryPreviewStatus.expiring,
              note: 'Pronto',
              quantity: '1 pza',
              thumbnail: ProductThumbnailKind.yogurt,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(sections: sections)),
      );

      // Los contadores dinámicos deben reflejar 1 caducado y 2 por caducar
      expect(
        find.text('Caducados'),
        findsNWidgets(2),
      ); // Chip y título de sección
      expect(find.text('Por caducar'), findsWidgets);
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('0'), findsWidgets);
      expect(find.text('3 artículos registrados'), findsOneWidget);

      // Tocar el chip de Caducados debe filtrar la lista
      await tester.tap(find.text('Caducados').first);
      await tester.pumpAndSettle();

      expect(find.text('Leche agria'), findsOneWidget);
      expect(find.text('Yogurt'), findsNothing);

      // Tocar de nuevo restaura todos los artículos
      await tester.tap(find.text('Caducados').first);
      await tester.pumpAndSettle();

      expect(find.text('Leche agria'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Yogurt'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Yogurt'), findsOneWidget);
    },
  );

  testWidgets('HomeScreen permite buscar productos por texto', (
    WidgetTester tester,
  ) async {
    final sections = [
      const PantrySectionPreview(
        title: 'Lácteos',
        caption: 'En orden',
        status: PantryPreviewStatus.healthy,
        products: [
          PantryProductPreview(
            name: 'Leche entera',
            category: 'Lácteos',
            status: PantryPreviewStatus.healthy,
            note: 'Fresco',
            quantity: '1 L',
            thumbnail: ProductThumbnailKind.milk,
          ),
          PantryProductPreview(
            name: 'Arroz blanco',
            category: 'Abarrotes',
            status: PantryPreviewStatus.healthy,
            note: 'En stock',
            quantity: '1 kg',
            thumbnail: ProductThumbnailKind.rice,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(MaterialApp(home: HomeScreen(sections: sections)));

    // Inicialmente ambos productos son visibles
    expect(find.text('Leche entera'), findsOneWidget);
    expect(find.text('Arroz blanco'), findsOneWidget);

    // Tocar el botón de buscar en la barra superior
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // Escribir "Leche" en el campo de búsqueda
    await tester.enterText(find.byType(TextField), 'Leche');
    await tester.pumpAndSettle();

    expect(find.text('Leche entera'), findsOneWidget);
    expect(find.text('Arroz blanco'), findsNothing);

    // Tocar el botón de cerrar búsqueda en la barra superior
    await tester.tap(find.byTooltip('Cerrar búsqueda'));
    await tester.pumpAndSettle();

    expect(find.text('Leche entera'), findsOneWidget);
    expect(find.text('Arroz blanco'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen inicia vacía sin datos semilla y muestra estado vacío',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen(sections: [])),
      );

      expect(find.text('0 artículos registrados'), findsOneWidget);
      expect(find.text('No hay artículos registrados'), findsOneWidget);
      expect(
        find.text('0'),
        findsWidgets,
      ); // 0 caducados, 0 por caducar, 0 por agotarse, 0 carrito
    },
  );

  testWidgets(
    'Productos del día muestra sus datos sin acciones de inventario',
    (WidgetTester tester) async {
      final alerts = [
        const CalendarAlertPreview(
          'Yogurt Griego',
          'Refrigerador',
          '2 pza',
          CalendarPreviewStatus.expiring,
          ProductThumbnailKind.placeholder,
          lotCode: 'L-101',
          loteId: 1,
          productoId: 10,
          cantidad: 2.0,
          unidad: 'pza',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: DayAlertsScreen(day: DateTime(2026, 10, 15), alerts: alerts),
        ),
      );

      // Verificar que 'Acción inteligente del día' fue eliminada
      expect(find.text('Acción inteligente del día'), findsNothing);
      expect(find.text('1 TAP'), findsNothing);

      expect(find.text('Yogurt Griego'), findsOneWidget);
      expect(find.text('2 pza'), findsOneWidget);
      expect(find.text('Por caducar'), findsNothing);
      expect(find.text('Caducidad: 15 de octubre de 2026'), findsOneWidget);
      expect(find.text('Consumir'), findsNothing);
      expect(find.text('Desechar'), findsNothing);
      expect(find.text('Anotar'), findsNothing);
      expect(find.byIcon(Icons.add_shopping_cart_outlined), findsNothing);
      expect(find.text('Lotes del día'), findsNothing);
      expect(find.byTooltip('Editar fecha de caducidad'), findsOneWidget);
      await tester.tap(find.text('Yogurt Griego'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ProductFormScreen), findsNothing);
    },
  );

  testWidgets('Una caducidad lejana muestra sus datos en Sin alerta', (
    tester,
  ) async {
    final product = calendarAlertFromLot(
      const Lote(
        id: 1,
        productoId: 1,
        productoNombre: 'Papas',
        unidad: 'g',
        cantidad: 100,
        presentacion: PresentacionCompra.bolsa,
        contenidoEnvase: 50,
        fechaCaducidad: '2999-01-01',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DayAlertsScreen(day: DateTime(2999), alerts: [product]),
      ),
    );
    await tester.pumpAndSettle();
    expect(product.status, CalendarPreviewStatus.healthy);
    expect(find.text('Papas'), findsOneWidget);
    expect(find.text('Bolsa de 50 g'), findsOneWidget);
    expect(find.text('2 bolsas de 50 g'), findsOneWidget);
    expect(find.text('Sin alerta (1)'), findsOneWidget);
    expect(find.text('Con alertas (0)'), findsOneWidget);
    expect(find.text('Por agotarse'), findsNothing);
    expect(find.text('Anotar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ProductFormScreen permite ingresar decimales con teclado, incluye ml y mantiene pantalla limpia',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: ProductFormScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verificar que la unidad 'ml' existe y se puede seleccionar
      expect(find.text('ml'), findsOneWidget);
      await tester.tap(find.text('ml'));
      await tester.pump();

      final minimum = find.byKey(const ValueKey('quantity-stock mínimo'));
      await Scrollable.ensureVisible(tester.element(minimum), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.enterText(minimum, '5,5');
      await tester.pump();
      expect(tester.widget<TextField>(minimum).controller!.text, '5,5');
      await tester.tap(find.byTooltip('Aumentar stock mínimo'));
      await tester.pump();
      expect(tester.widget<TextField>(minimum).controller!.text, '6.5');
      final quantity = find.byKey(const ValueKey('quantity-cantidad inicial'));
      await Scrollable.ensureVisible(tester.element(quantity), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.enterText(quantity, '10');
      await tester.pump();
      expect(tester.widget<TextField>(quantity).controller!.text, '10');

      // La pantalla se mantiene limpia sin alertas visuales de colores ni emojis
      expect(find.text('Existencias listas para almacenar'), findsOneWidget);
      expect(find.textContaining('menor al stock mínimo'), findsNothing);
      expect(find.textContaining('supera el stock mínimo'), findsNothing);
    },
  );

  testWidgets(
    'Carrito suma unidades en el badge y desaparece al vaciar la lista',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controller = ShoppingListsPreviewController();
      const product = PantryProductPreview(
        id: 99,
        name: 'Galletas Chispas',
        category: 'Snacks',
        status: PantryPreviewStatus.healthy,
        note: 'Stock: 10 pza',
        quantity: '10 pza',
        thumbnail: ProductThumbnailKind.placeholder,
      );

      await tester.pumpWidget(
        ShoppingListsPreviewScope(
          controller: controller,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final lists = ShoppingListsPreviewScope.of(context);
                return HomeScreen(
                  cartCount: lists.current.units,
                  sections: const [
                    PantrySectionPreview(
                      title: 'Snacks',
                      caption: 'En orden',
                      status: PantryPreviewStatus.healthy,
                      products: [product],
                    ),
                  ],
                  onAddToCart: (p) {
                    lists.addProduct(p);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${p.name}" agregado a la lista de compras',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // Al inicio, el carrito está vacío: el badge no debe mostrarse (showBadge = false)
      final badgeFinder = find.byKey(const ValueKey('home-cart-badge'));
      expect(badgeFinder, findsOneWidget);
      expect(tester.widget<badges.Badge>(badgeFinder).showBadge, isFalse);

      // Agregar primera galleta
      await tester.tap(find.byIcon(Icons.add_shopping_cart_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar SnackBar de confirmación
      expect(
        find.text('"Galletas Chispas" agregado a la lista de compras'),
        findsOneWidget,
      );
      // Badge debe estar visible y mostrar 1
      expect(tester.widget<badges.Badge>(badgeFinder).showBadge, isTrue);
      expect(
        find.descendant(of: badgeFinder, matching: find.text('1')),
        findsOneWidget,
      );

      // Agregar segunda galleta (mismo producto)
      await tester.tap(find.byIcon(Icons.add_shopping_cart_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Badge debe estar visible, sumar las cantidades y mostrar 2 (no 1)
      expect(tester.widget<badges.Badge>(badgeFinder).showBadge, isTrue);
      expect(
        find.descendant(of: badgeFinder, matching: find.text('2')),
        findsOneWidget,
      );
      expect(controller.current.items.length, 1);
      expect(controller.current.units, 2);

      // Vaciar el carrito
      controller.clearCurrent();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // El badge debe desaparecer (showBadge = false, 0 unidades)
      expect(controller.current.units, 0);
      expect(tester.widget<badges.Badge>(badgeFinder).showBadge, isFalse);
      expect(
        find.descendant(of: badgeFinder, matching: find.text('2')),
        findsNothing,
      );

      // Drenar temporizadores de SnackBar
      await tester.pumpAndSettle();
    },
  );
}
