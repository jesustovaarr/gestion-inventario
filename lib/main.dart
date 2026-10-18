import 'package:flutter/material.dart';
import 'package:gestion_inventario/screens/pantalla_confirmar_compra.dart';

import 'components/tema_alacena.dart';
import 'screens/pantalla_inicio.dart';
import 'screens/pantalla_carrito.dart';
import 'screens/pantalla_historial_compras.dart';
import 'screens/pantalla_tiendas.dart';
import 'screens/pantalla_nuevo_articulo.dart';
import 'screens/pantalla_calendario.dart';
import 'screens/formulario_producto.dart';
import 'presentation/controlador_carrito.dart';
import 'presentation/acciones_inventario.dart';

import 'database/daos/producto_dao.dart';
import 'presentation/modelos_vista_alacena.dart';

// Aplicacion principal
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlacenaPreviewApp());
}

class AlacenaPreviewApp extends StatefulWidget {
  const AlacenaPreviewApp({super.key});

  @override
  State<AlacenaPreviewApp> createState() => _AlacenaPreviewAppState();
}

class _AlacenaPreviewAppState extends State<AlacenaPreviewApp> {
  final _lists = ShoppingListsPreviewController();
  final _productoDao = ProductoDao();
  final Set<int> _accionesEnCurso = {};

  List<PantrySectionPreview> _seccionesBD = const [];

  @override
  void initState() {
    super.initState();
    _lists.addListener(_onCartChanged);
    _cargarDatosBD();
  }

  void _onCartChanged() async {
    try {
      final secciones = await obtenerSeccionesDesdeBD();
      if (mounted) setState(() => _seccionesBD = secciones);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _cargarDatosBD() async {
    try {
      final secciones = await obtenerSeccionesDesdeBD();
      await _lists.cargarDesdeBD();
      if (mounted) {
        setState(() {
          _seccionesBD = secciones;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _lists.removeListener(_onCartChanged);
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
          '/purchase-history': (_) => const PurchaseHistoryScreen(),
          '/new-article': (_) => const NewArticleScreen(),
          '/confirm-purchase': (_) => const ConfirmPurchaseScreen(),
        },
        home: Builder(
          builder: (context) {
            final lists = ShoppingListsPreviewScope.of(context);
            final badgeCount = lists.current.units;

            return HomeScreen(
              cartCount: badgeCount,
              sections: _seccionesBD,
              onInventoryAction: (product) async {
                if (product.id == null ||
                    _accionesEnCurso.contains(product.id)) {
                  return;
                }
                _accionesEnCurso.add(product.id!);
                try {
                  await actuarSobrePrimerLote(context, product.id!);
                  await _cargarDatosBD();
                } finally {
                  _accionesEnCurso.remove(product.id);
                }
              },
              onAddToCart: (product) {
                lists.addProduct(product);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '"${product.name}" agregado a la lista de compras',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onDeleteProduct: (product) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar del inventario'),
                    content: Text(
                      '¿Deseas eliminar "${product.name}" (${product.presentationLabel}) y sus lotes registrados?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: PantryColors.red,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && product.id != null) {
                  await _productoDao.eliminar(product.id!);
                  _cargarDatosBD();
                }
              },
              onAddProduct: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const NewArticleScreen(),
                  ),
                );
                if (res == true || mounted) {
                  _cargarDatosBD();
                }
              },
              onCart: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                );
                _cargarDatosBD();
              },
              onProductTap: (product) async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => ProductFormScreen(product: product),
                  ),
                );
                if (mounted) await _cargarDatosBD();
              },
            );
          },
        ),
      ),
    );
  }
}
