import 'package:flutter/material.dart';

import 'formulario_tienda.dart';

/// Entrada compatible con el catálogo; crear y editar comparten formulario.
class EditStoreScreen extends StatelessWidget {
  const EditStoreScreen({
    super.key,
    required this.storeName,
    required this.address,
    required this.purchases,
  });
  final String storeName;
  final String address;
  final int purchases;

  @override
  Widget build(BuildContext context) => StoreFormScreen(
    storeName: storeName,
    address: address,
    purchases: purchases,
  );
}
