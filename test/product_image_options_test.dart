import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tocar el placeholder de foto abre el menú de cámara y galería', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductFormScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // El avatar placeholder inicial muestra "Foto opcional" y 2 iconos de cámara
    expect(find.text('Foto opcional'), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNWidgets(2));

    // Al tocar el avatar se despliega el BottomSheet
    await tester.tap(find.text('Foto opcional'));
    await tester.pumpAndSettle();

    expect(find.text('Tomar fotografía'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
    expect(find.text('Quitar foto'), findsNothing); // Sin foto previa no hay opción de quitar

    // Cerrar el modal
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('Con foto inicial, muestra opción de cambiar y botón para quitar foto', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductFormScreen(initialImagePath: '/fotos/test_leche.jpg'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Al tener foto previa, muestra botón para cambiar foto y botón flotante para quitar foto
    final editBtn = find.byTooltip('Cambiar foto');
    expect(editBtn, findsOneWidget);
    expect(find.byTooltip('Quitar foto'), findsOneWidget);

    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tomar fotografía'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
    expect(find.text('Quitar foto'), findsOneWidget);

    // Tocar "Quitar foto" dentro del BottomSheet
    await tester.tap(find.text('Quitar foto'));
    await tester.pumpAndSettle();

    // Vuelve al estado inicial sin foto
    expect(find.text('Foto opcional'), findsOneWidget);
  });
}
