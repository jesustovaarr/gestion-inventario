import 'package:flutter/material.dart';

import 'components/tema_alacena.dart';
import 'screens/pantalla_inicio.dart';
import 'screens/pantalla_detalle_producto.dart';
import 'screens/pantalla_carrito.dart';
import 'screens/pantalla_tiendas.dart';
import 'screens/pantalla_nuevo_articulo.dart';
import 'screens/pantalla_calendario.dart';
import 'screens/formulario_producto.dart';
import 'widgets/acciones_deslizables_catalogo.dart';
import 'presentation/lista_compras_demostracion.dart';

/// Entrada independiente para revisar el diseño sin conectar la persistencia.
void main() => runApp(const AlacenaPreviewApp());

class AlacenaPreviewApp extends StatefulWidget {
  const AlacenaPreviewApp({super.key});

  @override
  State<AlacenaPreviewApp> createState() => _AlacenaPreviewAppState();
}

class _AlacenaPreviewAppState extends State<AlacenaPreviewApp> {
  final _lists = ShoppingListsPreviewController();

  @override
  void dispose() {
    _lists.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShoppingListsPreviewScope(
      controller: _lists,
      child: MaterialApp(
        title: 'Alacena',
        debugShowCheckedModeBanner: false,
        theme: PantryTheme.light,
        routes: {
          '/calendar': (_) => const CalendarScreen(),
          '/stores': (_) => const StoresScreen(),
          '/cart': (_) => const CartScreen(),
        },
        home: Builder(
          builder: (context) {
            final lists = ShoppingListsPreviewScope.of(context);
            return HomeScreen(
              cartCount: lists.current.items.length,
              onAddToCart: lists.addProduct,
              onEditProduct: (product) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductFormScreen(product: product),
                ),
              ),
              onDeleteProduct: (product) =>
                  showCatalogRemovalPreview(context, name: product.name),
              onAddProduct: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NewArticleScreen(),
                ),
              ),
              onCart: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              ),
              onProductTap: (product) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
