import 'package:flutter/material.dart';

import 'formulario_producto.dart';

/// Entrada para el botón +; reutiliza el formulario de edición de productos.
class NewArticleScreen extends StatelessWidget {
  const NewArticleScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProductFormScreen();
}
