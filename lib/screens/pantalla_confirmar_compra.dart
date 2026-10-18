import 'package:flutter/material.dart';

import '../presentation/modelos_vista_alacena.dart';
import 'pantalla_registrar_compra.dart';

/// Las rutas anteriores de confirmación utilizan el mismo formulario de compra.
class ConfirmPurchaseScreen extends StatelessWidget {
  const ConfirmPurchaseScreen({super.key, this.product, this.productoId});
  final PantryProductPreview? product;
  final int? productoId;
  @override
  Widget build(BuildContext context) => RegisterPurchaseScreen(
    product: product,
    productoId: productoId,
    useShoppingList: true,
  );
}
