import 'package:flutter/material.dart';

import 'pantalla_registrar_compra.dart';

/// El carrito es la lista de artículos de la compra que se está preparando.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const RegisterPurchaseScreen(useShoppingList: true, stayAfterSave: true);
}
