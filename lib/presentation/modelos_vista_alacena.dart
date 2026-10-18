import 'package:flutter/material.dart';

import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';

import '../components/tema_alacena.dart';
import '../widgets/miniatura_producto.dart';
import '../models/producto_model.dart';
import '../models/lote_model.dart';
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
  empty(
    'Sin existencias',
    Icons.inventory_2_outlined,
    Color(0xFF526C76),
    Color(0xFFE7EEF0),
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
    this.price,
    this.code,
    this.packaging = PresentacionCompra.granel,
    this.packageContent = 1,
    this.storageZone,
    this.expiryDate,
    this.lotId,
    this.lotQuantity = 0,
    this.totalStock,
    this.activeLots = const [],
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
  final double minimumStock;
  final double? price;
  final String? code;
  final PresentacionCompra packaging;
  final double packageContent;
  final String? storageZone;
  final String? expiryDate;
  final int? lotId;
  final double lotQuantity;
  final double? totalStock;
  final List<Lote> activeLots;
  String get key => (id ?? name).toString();
  String get presentationLabel =>
      etiquetaPresentacion(packaging, packageContent, unit);
  double get availableQuantity => totalStock ?? lotQuantity;
  String get totalStockLabel =>
      '${formatearContenido(availableQuantity, unit)} en total';
  String get stockLabel {
    if (!hasStock) {
      return packaging.esEnvase
          ? '0 ${packaging.plural} en stock'
          : '0 ${unidadVisible(unit)} en stock';
    }
    return describirExistencia(
      cantidad: availableQuantity,
      unidad: unit,
      presentacion: packaging,
      contenidoEnvase: packageContent,
    );
  }

  String? get stockDetail =>
      hasStock && packaging.esEnvase ? totalStockLabel : null;

  int? get daysToExpiry {
    final date = DateTime.tryParse(expiryDate ?? '');
    if (date == null) return null;
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isExpired => (daysToExpiry ?? 0) < 0;
  String get expiryLabel {
    final days = daysToExpiry;
    if (days == null) return 'Sin fecha de caducidad';
    if (days == -1) return 'Caducado ayer';
    if (days < 0) return 'Caducado hace ${-days} días';
    if (days == 0) return 'Caduca hoy';
    if (days == 1) return 'Caduca mañana';
    return 'Caduca en $days días';
  }

  String get formattedExpiry {
    final date = DateTime.tryParse(expiryDate ?? '');
    if (date == null) return 'Caducidad sin registrar';
    return 'Cad: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get lotQuantityLabel => '${formatearCantidad(lotQuantity)} $unit';
  bool get hasStock => normalizarCantidad(availableQuantity) > 0;
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
    const estados = {
      EstadoProducto.caducado: PantryPreviewStatus.expired,
      EstadoProducto.agotado: PantryPreviewStatus.empty,
      EstadoProducto.porCaducar: PantryPreviewStatus.expiring,
      EstadoProducto.porAgotarse: PantryPreviewStatus.lowStock,
      EstadoProducto.enOrden: PantryPreviewStatus.healthy,
    };
    return PantryProductPreview(
      id: id,
      name: nombre,
      category: categoriaNombre ?? 'Abarrotes',
      status: estados[estado]!,
      note: 'Stock: ${formatearCantidad(stockActual)} $unidadMedida',
      quantity: '${formatearCantidad(stockActual)} $unidadMedida',
      thumbnail: ProductThumbnailKind.placeholder,
      imagePath: imagen.isEmpty || imagen == 'assets/images/default_product.png'
          ? null
          : imagen,
      unit: unidadMedida,
      minimumStock: stockMinimo,
      price: precio,
      code: codigo,
      packaging: PresentacionCompra.leer(presentacion),
      packageContent: contenidoEnvase,
      storageZone: zonaAlmacenamiento,
      expiryDate: proximaCaducidad,
      lotId: primerLoteId,
      lotQuantity: cantidadPrimerLote,
      totalStock: stockActual,
      activeLots: lotesActivos,
    );
  }
}

// Helper para obtener secciones agrupadas dinámicamente desde SQLite
Future<List<PantrySectionPreview>> obtenerSeccionesDesdeBD() async {
  final productos = await ProductoDao().obtenerConStock();
  if (productos.isEmpty) return [];

  return [
    PantrySectionPreview(
      title: 'Productos',
      caption: 'Primero los que caducan antes',
      status: PantryPreviewStatus.healthy,
      products: productos.map((p) => p.toPreview()).toList(),
    ),
  ];
}
