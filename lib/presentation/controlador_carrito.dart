import 'package:flutter/material.dart';

import 'modelos_vista_alacena.dart';
import '../database/daos/carrito_dao.dart';
import '../widgets/miniatura_producto.dart';

class ShoppingListItemPreview {
  const ShoppingListItemPreview(this.product, this.quantity);
  final PantryProductPreview product;
  final int quantity;
}

class ShoppingListPreview {
  ShoppingListPreview({
    required this.id,
    required this.name,
    required List<ShoppingListItemPreview> items,
  }) : items = List.unmodifiable(items);
  final int id;
  final String name;
  final List<ShoppingListItemPreview> items;
  int get units => items.fold(0, (sum, item) => sum + item.quantity);

  ShoppingListPreview copyWith({
    String? name,
    List<ShoppingListItemPreview>? items,
  }) =>
      ShoppingListPreview(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
      );
}

/// Controlador de la lista de compras sincronizado con SQLite CarritoDao
class ShoppingListsPreviewController extends ChangeNotifier {
  final CarritoDao _carritoDao = CarritoDao();

  ShoppingListsPreviewController() {
    _current = ShoppingListPreview(
      id: 1,
      name: 'Mi lista',
      items: [],
    );
    cargarDesdeBD();
  }

  late ShoppingListPreview _current;
  ShoppingListPreview get current => _current;

  void _replace(ShoppingListPreview list) {
    _current = list;
  }

  Future<void> cargarDesdeBD() async {
    try {
      final itemsBD = await _carritoDao.obtenerItems();
      final previewItems = itemsBD.map((item) {
        return ShoppingListItemPreview(
          PantryProductPreview(
            id: item.productoId,
            name: item.productoNombre ?? 'Artículo',
            category: 'Inventario',
            status: (item.stockActual ?? 0) <= 0
                ? PantryPreviewStatus.expired
                : PantryPreviewStatus.healthy,
            note:
                'Stock: ${(item.stockActual ?? 0).toInt()} ${item.unidadMedida ?? "pza"}',
            quantity:
                '${(item.stockActual ?? 0).toInt()} ${item.unidadMedida ?? "pza"}',
            unit: item.unidadMedida ?? 'pza',
            thumbnail: ProductThumbnailKind.placeholder,
            imagePath: item.imagen,
          ),
          item.cantidadAComprar.toInt() <= 0
              ? 1
              : item.cantidadAComprar.toInt(),
        );
      }).toList();

      _replace(_current.copyWith(items: previewItems));
      notifyListeners();
    } catch (_) {}
  }

  void renameCurrent(String name) {
    _replace(current.copyWith(name: name));
    notifyListeners();
  }

  bool _isSameProduct(PantryProductPreview a, PantryProductPreview b) {
    if (a.id != null && b.id != null) {
      return a.id == b.id;
    }
    return a.name == b.name;
  }

  Future<void> addProduct(PantryProductPreview product) async {
    final items = current.items.toList();
    final index = items.indexWhere((item) => _isSameProduct(item.product, product));
    if (index < 0) {
      items.add(ShoppingListItemPreview(product, 1));
    } else {
      items[index] = ShoppingListItemPreview(
        product,
        items[index].quantity + 1,
      );
    }
    _replace(current.copyWith(items: items));
    notifyListeners();

    if (product.id != null) {
      try {
        await _carritoDao.agregarOIncrementar(product.id!);
      } catch (_) {}
    }
  }

  Future<void> changeQuantity(PantryProductPreview product, int delta) async {
    final items = <ShoppingListItemPreview>[];
    int nuevaCant = 1;
    for (final item in current.items) {
      final match = _isSameProduct(item.product, product);
      if (match) {
        nuevaCant = (item.quantity + delta).clamp(1, 999);
        items.add(ShoppingListItemPreview(item.product, nuevaCant));
      } else {
        items.add(item);
      }
    }
    _replace(current.copyWith(items: items));
    notifyListeners();

    if (product.id != null) {
      try {
        await _carritoDao.actualizarCantidad(
          product.id!,
          nuevaCant.toDouble(),
        );
      } catch (_) {}
    }
  }

  Future<void> removeProduct(PantryProductPreview product) async {
    _replace(
      current.copyWith(
        items: current.items
            .where((item) => !_isSameProduct(item.product, product))
            .toList(),
      ),
    );
    notifyListeners();

    if (product.id != null) {
      try {
        await _carritoDao.eliminar(product.id!);
      } catch (_) {}
    }
  }

  Future<void> clearCurrent() async {
    _replace(current.copyWith(items: []));
    notifyListeners();
    try {
      await _carritoDao.vaciar();
    } catch (_) {}
  }
}

class ShoppingListsPreviewScope
    extends InheritedNotifier<ShoppingListsPreviewController> {
  const ShoppingListsPreviewScope({
    super.key,
    required ShoppingListsPreviewController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShoppingListsPreviewController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ShoppingListsPreviewScope>()
          ?.notifier;
  static ShoppingListsPreviewController of(BuildContext context) =>
      maybeOf(context)!;
}
