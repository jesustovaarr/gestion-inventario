import 'package:flutter/material.dart';

import 'modelos_vista_alacena.dart';
import 'modelos_vista_compra.dart';
import '../database/daos/carrito_dao.dart';
import '../database/daos/producto_dao.dart';
import '../models/carrito_model.dart';
import '../utils/cantidades.dart';

class ShoppingListItemPreview extends PurchaseArticleDraft {
  const ShoppingListItemPreview(
    PantryProductPreview product,
    double quantity, {
    super.priceCents,
    super.expiryDate,
    super.packaging,
    super.packageCount,
    super.packageContent,
  }) : super(product: product, quantity: quantity);
  factory ShoppingListItemPreview.fromDraft(PurchaseArticleDraft item) =>
      ShoppingListItemPreview(
        item.product,
        item.quantity,
        priceCents: item.priceCents,
        expiryDate: item.expiryDate,
        packaging: item.packaging,
        packageCount: item.packageCount,
        packageContent: item.packageContent,
      );
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
  double get units => items.fold(
    0.0,
    (sum, item) => sum + (item.packaging.esEnvase ? item.packageCount : 1),
  );
  ShoppingListPreview copyWith({
    String? name,
    List<ShoppingListItemPreview>? items,
  }) => ShoppingListPreview(
    id: id,
    name: name ?? this.name,
    items: items ?? this.items,
  );
}

class ShoppingListsPreviewController extends ChangeNotifier {
  final CarritoDao _carritoDao = CarritoDao();
  ShoppingListsPreviewController() {
    cargarDesdeBD();
  }
  ShoppingListPreview _current = ShoppingListPreview(
    id: 1,
    name: 'Mi lista',
    items: [],
  );
  ShoppingListPreview get current => _current;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _replace(List<ShoppingListItemPreview> items) {
    items.sort((a, b) => a.product.name.compareTo(b.product.name));
    _current = current.copyWith(items: items);
    if (!_disposed) notifyListeners();
  }

  Future<void> cargarDesdeBD() async {
    try {
      final rows = await _carritoDao.obtenerItems();
      final products = await ProductoDao().obtenerConStock();
      if (_disposed) return;
      final byId = {for (final p in products) p.id: p.toPreview()};
      _replace([
        for (final item in rows)
          if (byId[item.productoId] != null)
            _stored(item, byId[item.productoId]!),
      ]);
    } catch (_) {}
  }

  ShoppingListItemPreview _stored(
    CarritoItem item,
    PantryProductPreview product,
  ) {
    final reference = product.price == null
        ? null
        : product.price! *
              100 *
              (item.presentacion.esEnvase ? item.contenidoEnvase : 1);
    return ShoppingListItemPreview(
      product,
      item.cantidadAComprar,
      packaging: item.presentacion,
      packageCount: item.numeroEnvases,
      packageContent: item.contenidoEnvase,
      priceCents:
          item.precioCentavos ??
          (reference != null &&
                  reference.isFinite &&
                  reference >= 0 &&
                  reference <= 99999999
              ? reference.round()
              : null),
      expiryDate: DateTime.tryParse(item.fechaCaducidad ?? ''),
    );
  }

  void _setLocal(PurchaseArticleDraft item) {
    final next = ShoppingListItemPreview.fromDraft(item);
    final items = current.items.toList();
    final index = items.indexWhere((i) => i.key == item.key);
    if (index < 0) {
      items.add(next);
    } else {
      items[index] = next;
    }
    _replace(items);
  }

  Future<void> setItem(PurchaseArticleDraft item) async {
    if (!cantidadValida(item.quantity)) {
      throw ArgumentError('Cantidad inválida');
    }
    if (item.product.id != null) {
      await _carritoDao.guardarArticulo(item.toCartItem());
    }
    if (!_disposed) _setLocal(item);
  }

  Future<void> addProduct(PantryProductPreview product) async {
    final candidate = PurchaseArticleDraft.fromProduct(product);
    final old = current.items.where((i) => i.key == candidate.key).firstOrNull;
    final item = old == null
        ? candidate
        : old.packaging.esEnvase
        ? old.copyWith(product: product, packageCount: old.packageCount + 1)
        : old.copyWith(
            product: product,
            quantity: normalizarCantidad(old.quantity + 1),
          );
    if (!cantidadValida(item.quantity) || item.packageCount > 999999) return;
    _setLocal(item);
    if (product.id != null) {
      try {
        await _carritoDao.guardarArticulo(item.toCartItem());
      } catch (_) {}
    }
  }

  Future<void> removeProduct(PantryProductPreview product) async {
    final item = current.items
        .where((i) => i.key == PurchaseArticleDraft.fromProduct(product).key)
        .firstOrNull;
    if (item != null) await removeItem(item);
  }

  Future<void> removeItem(PurchaseArticleDraft item) async {
    if (item.product.id != null) {
      try {
        await _carritoDao.eliminarArticulo(item.toCartItem());
      } catch (_) {}
    }
    _replace(current.items.where((i) => i.key != item.key).toList());
  }

  Future<void> clearCurrent() async {
    _replace([]);
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
