import 'package:flutter/material.dart';

import '../presentation/modelos_vista_alacena.dart';
import 'formulario_producto.dart';

/// Las entradas antiguas al detalle también llevan directamente a la edición.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.fromShoppingList = false,
  });
  final PantryProductPreview product;
  final bool fromShoppingList;
  @override
  Widget build(BuildContext context) => ProductFormScreen(product: product);
}
