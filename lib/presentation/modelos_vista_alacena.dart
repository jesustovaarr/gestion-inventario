import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../widgets/miniatura_producto.dart';
import '../models/producto_model.dart';
import '../database/daos/producto_dao.dart';

// Estados de presentación visual para productos de la alacena
enum PantryPreviewStatus {
  expired(
    'Caducado',
    Icons.error_outline_rounded,
    PantryColors.red,
    PantryColors.redLight,
  ),
  expiring(
    'Por caducar',
    Icons.hourglass_bottom_rounded,
    PantryColors.orange,
    PantryColors.orangeLight,
  ),
  lowStock(
    'Por agotarse',
    Icons.warning_amber_rounded,
    PantryColors.amber,
    PantryColors.amberLight,
  ),
  healthy(
    'En orden',
    Icons.check_circle_outline_rounded,
    PantryColors.green,
    PantryColors.greenLight,
  );

  const PantryPreviewStatus(this.label, this.icon, this.color, this.background);

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

// Modelo de vista para mostrar productos en tarjetas e interfaces de la alacena
class PantryProductPreview {
  const PantryProductPreview({
    this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.note,
    required this.quantity,
    required this.thumbnail,
    this.imagePath,
    this.unit = 'pza',
    this.minimumStock = 2,
  });

  final int? id;
  final String name;
  final String category;
  final PantryPreviewStatus status;
  final String note;
  final String quantity;
  final ProductThumbnailKind thumbnail;
  final String? imagePath;
  final String unit;
  final int minimumStock;
}

// Agrupación visual de productos por estado en la pantalla de inicio
class PantrySectionPreview {
  const PantrySectionPreview({
    required this.title,
    required this.caption,
    required this.status,
    required this.products,
  });

  final String title;
  final String caption;
  final PantryPreviewStatus status;
  final List<PantryProductPreview> products;
}

// Extensión para mapear entidades reales de SQLite Producto a modelos de vista
extension ProductoToPreview on Producto {
  PantryProductPreview toPreview() {
    PantryPreviewStatus s;
    switch (estado) {
      case EstadoProducto.caducado:
        s = PantryPreviewStatus.expired;
        break;
      case EstadoProducto.porCaducar:
        s = PantryPreviewStatus.expiring;
        break;
      case EstadoProducto.porAgotarse:
      case EstadoProducto.agotado:
        s = PantryPreviewStatus.lowStock;
        break;
      case EstadoProducto.enOrden:
        s = PantryPreviewStatus.healthy;
        break;
    }

    return PantryProductPreview(
      id: id,
      name: nombre,
      category: categoriaNombre ?? 'Abarrotes',
      status: s,
      note: 'Stock: ${stockActual.toInt()} $unidadMedida (Mínimo: ${stockMinimo.toInt()})',
      quantity: '${stockActual.toInt()} $unidadMedida',
      thumbnail: ProductThumbnailKind.placeholder,
      imagePath: (imagen.isNotEmpty && imagen != 'assets/images/default_product.png') ? imagen : null,
      unit: unidadMedida,
      minimumStock: stockMinimo.toInt(),
    );
  }
}

// Helper para obtener secciones agrupadas dinámicamente desde SQLite
Future<List<PantrySectionPreview>> obtenerSeccionesDesdeBD() async {
  final productos = await ProductoDao().obtenerConStock();
  if (productos.isEmpty) return [];

  final caducados = productos
      .where((p) => p.estado == EstadoProducto.caducado)
      .map((p) => p.toPreview())
      .toList();
  final porCaducar = productos
      .where((p) => p.estado == EstadoProducto.porCaducar)
      .map((p) => p.toPreview())
      .toList();
  final porAgotarse = productos
      .where((p) => p.estado == EstadoProducto.porAgotarse || p.estado == EstadoProducto.agotado)
      .map((p) => p.toPreview())
      .toList();
  final enOrden = productos
      .where((p) => p.estado == EstadoProducto.enOrden)
      .map((p) => p.toPreview())
      .toList();

  final List<PantrySectionPreview> secciones = [];
  if (caducados.isNotEmpty) {
    secciones.add(PantrySectionPreview(
      title: 'Caducados',
      caption: '${caducados.length} para desechar',
      status: PantryPreviewStatus.expired,
      products: caducados,
    ));
  }
  if (porCaducar.isNotEmpty) {
    secciones.add(PantrySectionPreview(
      title: 'Por caducar',
      caption: '${porCaducar.length} en 3 días',
      status: PantryPreviewStatus.expiring,
      products: porCaducar,
    ));
  }
  if (porAgotarse.isNotEmpty) {
    secciones.add(PantrySectionPreview(
      title: 'Por agotarse',
      caption: '${porAgotarse.length} por reponer',
      status: PantryPreviewStatus.lowStock,
      products: porAgotarse,
    ));
  }
  if (enOrden.isNotEmpty) {
    secciones.add(PantrySectionPreview(
      title: 'En orden',
      caption: '${enOrden.length} con stock suficiente',
      status: PantryPreviewStatus.healthy,
      products: enOrden,
    ));
  }
  return secciones;
}
