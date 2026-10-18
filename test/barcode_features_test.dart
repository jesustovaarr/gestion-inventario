import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gestion_inventario/models/datos_escaneo_producto.dart';
import 'package:gestion_inventario/services/servicio_open_food_facts.dart';
import 'package:gestion_inventario/services/servicio_precios_referencia.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';
import 'package:gestion_inventario/widgets/campo_codigo_barras.dart';
import 'package:gestion_inventario/widgets/escaner_codigo_barras.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/widgets/tarjeta_producto.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';
import 'package:gestion_inventario/widgets/visualizador_codigo_barras.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServicioOpenFoodFacts', () {
    test('Parsea correctamente respuesta de Open Food Facts para leche', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('7501020512100')) {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name_es': 'Leche Entera',
                'brands': 'Lala',
                'categories': 'Lácteos, Leches',
                'quantity': '1 L',
                'image_front_url': 'https://images.openfoodfacts.org/leche.jpg',
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = ServicioOpenFoodFacts(client: mockClient);
      final resultado = await service.consultarCodigo('7501020512100');

      expect(resultado, isNotNull);
      expect(resultado!.nombre, 'Leche Entera Lala');
      expect(resultado.categoria, 'Lácteos');
      expect(resultado.unidad, 'L');
      expect(resultado.contenidoEnvase, 1.0);
      expect(resultado.presentacion, PresentacionCompra.carton);
      expect(resultado.imagenUrl, 'https://images.openfoodfacts.org/leche.jpg');
    });

    test('Parsea correctamente bebida en botella de 600 ml', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name_es': 'Refresco de cola',
              'brands': 'Coca-Cola',
              'categories': 'Bebidas, Refrescos',
              'quantity': '600 ml',
              'packaging': 'botella de plástico',
            },
          }),
          200,
        );
      });

      final service = ServicioOpenFoodFacts(client: mockClient);
      final resultado = await service.consultarCodigo('7501055305142');

      expect(resultado, isNotNull);
      expect(resultado!.nombre, 'Refresco de Cola Coca-Cola');
      expect(resultado.categoria, 'Bebidas');
      expect(resultado.unidad, 'ml');
      expect(resultado.contenidoEnvase, 600.0);
      expect(resultado.presentacion, PresentacionCompra.botella);
    });

    test('Deduplica marcas repetidas y asigna presentación botella a Coca Cola 3L', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name_es': 'Coca cola',
              'brands': 'Coca-cola',
              'categories': 'Bebidas, Refrescos',
              'quantity': '3 L',
              'packaging': 'PET',
            },
          }),
          200,
        );
      });

      final service = ServicioOpenFoodFacts(client: mockClient);
      final resultado = await service.consultarCodigo('7501055303885');

      expect(resultado, isNotNull);
      expect(resultado!.nombre, 'Coca Cola');
      expect(resultado.categoria, 'Bebidas');
      expect(resultado.unidad, 'L');
      expect(resultado.contenidoEnvase, 3.0);
      expect(resultado.presentacion, PresentacionCompra.botella);
    });

    test('Deduplica tokens repetidos en el nombre e infiere botella para bebidas', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Coca cola Coca-cola 3l',
              'brands': '',
              'categories': 'Bebidas',
              'quantity': '3l',
            },
          }),
          200,
        );
      });

      final service = ServicioOpenFoodFacts(client: mockClient);
      final resultado = await service.consultarCodigo('7501055303885');

      expect(resultado, isNotNull);
      expect(resultado!.nombre, 'Coca Cola 3 L');
      expect(resultado.presentacion, PresentacionCompra.botella);
      expect(resultado.contenidoEnvase, 3.0);
      expect(resultado.unidad, 'L');
    });

    test('Devuelve null ante error 404 o producto no encontrado', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': 0}), 200);
      });

      final service = ServicioOpenFoodFacts(client: mockClient);
      final resultado = await service.consultarCodigo('9999999999999');

      expect(resultado, isNull);
    });
  });

  group('ServicioPreciosReferencia', () {
    final catalogoPrueba = {
      'productos_por_codigo': {
        '7501020512100': {
          'nombre': 'Leche Entera Lala 1 L',
          'categoria': 'Lácteos',
          'precio': 28.50,
          'unidad': 'L',
          'presentacion': 'carton',
          'contenido': 1.0,
        },
        '7501055303885': {
          'nombre': 'Coca-Cola Original 3 L',
          'categoria': 'Bebidas',
          'precio': 48.00,
          'unidad': 'L',
          'presentacion': 'botella',
          'contenido': 3.0,
        },
      },
      'precios_por_categoria': {
        'Bebidas': 22.00,
        'Lácteos': 26.00,
        'Granos': 34.00,
        'Otros': 25.00,
      },
    };

    test('Obtiene precio exacto por código de producto', () async {
      final service = ServicioPreciosReferencia.conDatos(catalogoPrueba);
      final precio = await service.obtenerPrecio(
        codigo: '7501020512100',
        categoria: 'Lácteos',
      );
      expect(precio, 28.50);
    });

    test('Obtiene precio exacto de Coca-Cola 3 L del catálogo', () async {
      final service = ServicioPreciosReferencia.conDatos(catalogoPrueba);
      final precio = await service.obtenerPrecio(
        codigo: '7501055303885',
        categoria: 'Bebidas',
      );
      expect(precio, 48.00);
    });

    test('Escala precio proporcionalmente por volumen para 3 L en Bebidas cuando el código no existe', () async {
      final service = ServicioPreciosReferencia.conDatos(catalogoPrueba);
      final precio = await service.obtenerPrecio(
        codigo: '9999999999999',
        categoria: 'Bebidas',
        contenido: 3.0,
        unidad: 'L',
      );
      // 22.0 * (1.0 + (3.0 - 1.0) * 0.60) = 48.40
      expect(precio, 48.40);
    });

    test('Usa precio de categoría como respaldo cuando el código no existe', () async {
      final service = ServicioPreciosReferencia.conDatos(catalogoPrueba);
      final precio = await service.obtenerPrecio(
        codigo: '0000000000000',
        categoria: 'Granos',
      );
      expect(precio, 34.00);
    });

    test('Obtiene datos completos precargados de producto por código', () async {
      final service = ServicioPreciosReferencia.conDatos(catalogoPrueba);
      final datos = await service.obtenerDatosPorCodigo('7501020512100');

      expect(datos, isNotNull);
      expect(datos!.nombre, 'Leche Entera Lala 1 L');
      expect(datos.categoria, 'Lácteos');
      expect(datos.precioSugerido, 28.50);
      expect(datos.presentacion, PresentacionCompra.carton);
    });
  });

  group('Widget CampoCodigoBarras y Formulario', () {
    testWidgets('CampoCodigoBarras se renderiza en el formulario de producto', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductFormScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Se muestra la etiqueta y el campo de código de barras
      expect(find.text('Código de barras'), findsOneWidget);
      expect(find.byKey(const Key('input_codigo_barras')), findsOneWidget);
      expect(find.byKey(const Key('btn_escanear_codigo')), findsOneWidget);
    });

    testWidgets('EscanerCodigoBarrasSheet permite ingresar código manual y retornar', (
      tester,
    ) async {
      String? codigoObtenido;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  codigoObtenido = await EscanerCodigoBarrasSheet.abrir(
                    context,
                    autoStartCamera: false,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Escanear código de barras'), findsOneWidget);
      expect(find.byKey(const Key('btn_toggle_modo_manual')), findsOneWidget);

      // Cambiar a entrada manual
      await tester.tap(find.byKey(const Key('btn_toggle_modo_manual')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_codigo_manual')), findsOneWidget);
      expect(find.byKey(const Key('btn_confirmar_codigo_manual')), findsOneWidget);

      // Ingresar código y aceptar
      await tester.enterText(
        find.byKey(const Key('input_codigo_manual')),
        '7501020512100',
      );
      await tester.tap(find.byKey(const Key('btn_confirmar_codigo_manual')));
      await tester.pumpAndSettle();

      expect(codigoObtenido, '7501020512100');
    });

    testWidgets('Resolver código autocompleta nombre, categoría y precio', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name_es': 'Leche Entera',
              'brands': 'Lala',
              'categories': 'Lácteos',
              'quantity': '1 L',
            },
          }),
          200,
        );
      });

      final offService = ServicioOpenFoodFacts(client: mockClient);
      final refService = ServicioPreciosReferencia.conDatos({
        'productos_por_codigo': {
          '7501020512100': {
            'nombre': 'Leche Entera Lala 1 L',
            'categoria': 'Lácteos',
            'precio': 28.50,
            'unidad': 'L',
            'presentacion': 'carton',
            'contenido': 1.0,
          },
        },
      });

      final codeController = TextEditingController();
      DatosEscaneoProducto? resultado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampoCodigoBarras(
              controller: codeController,
              autoStartCamera: false,
              openFoodFactsService: offService,
              preciosReferenciaService: refService,
              onProductResolved: (datos) {
                resultado = datos;
              },
            ),
          ),
        ),
      );

      // Ingresar código en el campo
      await tester.enterText(
        find.byKey(const Key('input_codigo_barras')),
        '7501020512100',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_buscar_codigo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(resultado, isNotNull);
      expect(resultado!.nombre, 'Leche Entera Lala 1 L');
      expect(resultado!.categoria, 'Lácteos');
      expect(resultado!.precioSugerido, 28.50);
    });

    testWidgets('Escanear un segundo producto actualiza nombre y precio en el formulario', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductFormScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final campoFinder = find.byType(CampoCodigoBarras);
      expect(campoFinder, findsOneWidget);
      final campoWidget = tester.widget<CampoCodigoBarras>(campoFinder);

      // Primer escaneo: Leche Lala
      campoWidget.onProductResolved(
        const DatosEscaneoProducto(
          codigo: '7501020512100',
          nombre: 'Leche Entera Lala 1 L',
          categoria: 'Lácteos',
          precioSugerido: 28.50,
          unidad: 'L',
          contenidoEnvase: 1.0,
          presentacion: PresentacionCompra.carton,
        ),
      );
      await tester.pump();

      expect(find.text('Leche Entera Lala 1 L'), findsOneWidget);
      expect(find.text('28.50'), findsOneWidget);

      // Segundo escaneo consecutivo: Coca-Cola 3 L
      campoWidget.onProductResolved(
        const DatosEscaneoProducto(
          codigo: '7501055303885',
          nombre: 'Coca-Cola Original 3 L',
          categoria: 'Bebidas',
          precioSugerido: 48.00,
          unidad: 'L',
          contenidoEnvase: 3.0,
          presentacion: PresentacionCompra.botella,
        ),
      );
      await tester.pump();

      expect(find.text('Coca-Cola Original 3 L'), findsOneWidget);
      expect(find.text('48.00'), findsOneWidget);
      expect(find.text('Leche Entera Lala 1 L'), findsNothing);
      expect(find.text('28.50'), findsNothing);
    });
  });

  group('Generador y Visualizador de Código de Barras', () {
    test('Calcula checksum EAN-13 correctamente para Coca-Cola', () {
      final checksum = GeneradorCodigoBarras.calcularChecksumEan('750105530007');
      expect(checksum, 5);
      expect(GeneradorCodigoBarras.esEan13('7501055300075'), isTrue);
    });

    test('Genera 95 módulos binarios para un EAN-13 estándar', () {
      final bits = GeneradorCodigoBarras.generarBits('7501055300075');
      expect(bits.length, 95);
      expect(bits.startsWith('101'), isTrue); // Left guard
      expect(bits.endsWith('101'), isTrue); // Right guard
      expect(bits.substring(45, 50), '01010'); // Center guard
    });

    test('Genera Code 128 Set B para códigos alfanuméricos', () {
      final bits = GeneradorCodigoBarras.generarBits('ALACENA-123');
      expect(bits.isNotEmpty, isTrue);
      expect(GeneradorCodigoBarras.tipoSimbologia('ALACENA-123'), 'Code 128');
    });

    testWidgets('VisualizadorCodigoBarras dibuja las barras y texto', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisualizadorCodigoBarras(
              codigo: '7501055300075',
              altura: 80,
              mostrarTexto: true,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('7  501055  300075'), findsOneWidget);
    });

    testWidgets('CampoCodigoBarras muestra botón de visualización y abre modal', (
      tester,
    ) async {
      final controller = TextEditingController(text: '7501055300075');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampoCodigoBarras(
              controller: controller,
              onProductResolved: (_) {},
            ),
          ),
        ),
      );

      final btnVerFinder = find.byKey(const Key('btn_ver_codigo_generado'));
      expect(btnVerFinder, findsOneWidget);

      await tester.tap(btnVerFinder);
      await tester.pumpAndSettle();

      expect(find.byType(VisualizadorCodigoBarrasModal), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(VisualizadorCodigoBarrasModal),
          matching: find.text('Código de barras'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Simbología EAN-13'), findsOneWidget);
      expect(find.byKey(const Key('btn_copiar_codigo_modal')), findsOneWidget);

      // Cerrar modal
      await tester.tap(find.byKey(const Key('btn_cerrar_codigo_modal')));
      await tester.pumpAndSettle();

      expect(find.byType(VisualizadorCodigoBarrasModal), findsNothing);
    });

    testWidgets('ProductCard muestra código de barras y abre modal al tocarlo', (
      tester,
    ) async {
      const preview = PantryProductPreview(
        id: 99,
        name: 'Salsa Botanera',
        category: 'Abarrotes',
        status: PantryPreviewStatus.healthy,
        note: 'Stock: 4 pza',
        quantity: '4 pza',
        thumbnail: ProductThumbnailKind.placeholder,
        code: '7501055300075',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductCard(product: preview),
          ),
        ),
      );

      final chipCodigo = find.byKey(const Key('btn_codigo_producto_99'));
      expect(chipCodigo, findsOneWidget);
      expect(find.text('7501055300075'), findsOneWidget);
      expect(find.text('Ver código'), findsOneWidget);

      await tester.tap(chipCodigo);
      await tester.pumpAndSettle();

      expect(find.byType(VisualizadorCodigoBarrasModal), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(VisualizadorCodigoBarrasModal),
          matching: find.text('Salsa Botanera'),
        ),
        findsOneWidget,
      );
    });
  });
}
