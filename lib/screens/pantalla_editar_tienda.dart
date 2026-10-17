import 'package:flutter/material.dart';

import 'formulario_tienda.dart';

class EditStoreScreen extends StatelessWidget {
  const EditStoreScreen({
    super.key,
    this.storeId,
    required this.storeName,
    required this.address,
    required this.purchases,
    this.tipoTiendaId,
  });

  final int? storeId;
  final String storeName;
  final String address;
  final int purchases;
  final int? tipoTiendaId;

  @override
  Widget build(BuildContext context) => StoreFormScreen(
        storeId: storeId,
        storeName: storeName,
        address: address,
        purchases: purchases,
        tipoTiendaId: tipoTiendaId,
      );
}
