import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../models/lote_model.dart';
import '../utils/presentaciones.dart';
import '../widgets/miniatura_producto.dart';

// Estados visuales para alertas en la vista de calendario
enum CalendarPreviewStatus {
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
    'Sin alerta',
    Icons.check_circle_outline_rounded,
    PantryColors.green,
    PantryColors.greenLight,
  );

  const CalendarPreviewStatus(
    this.label,
    this.icon,
    this.color,
    this.background,
  );
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

// Modelo de alerta para días en el calendario con lotes de SQLite
class CalendarAlertPreview {
  const CalendarAlertPreview(
    this.name,
    this.location,
    this.quantity,
    this.status,
    this.thumbnail, {
    this.lotCode = 'L-1094',
    this.loteId,
    this.productoId,
    this.cantidad = 1.0,
    this.unidad = 'pza',
    this.imagePath,
    this.alarmaActiva = 1,
    this.horaAviso = '09:00 AM',
    this.porAgotarse = false,
    this.stockTotal,
    this.stockMinimo,
    this.storageZone,
    this.category,
    this.fechaCaducidad,
  });
  final String name;
  final String location;
  final String quantity;
  final CalendarPreviewStatus status;
  final ProductThumbnailKind thumbnail;
  final String lotCode;
  final int? loteId;
  final int? productoId;
  final double cantidad;
  final String unidad;
  final String? imagePath;
  final int alarmaActiva;
  final String horaAviso;
  final bool porAgotarse;
  final double? stockTotal;
  final double? stockMinimo;
  final String? storageZone;
  final String? category;
  final String? fechaCaducidad;
}

/// Los estados del calendario distinguen caducado, por caducar, por agotarse y sin alerta.
CalendarAlertPreview calendarAlertFromLot(Lote lote) {
  final status = lote.estaCaducado
      ? CalendarPreviewStatus.expired
      : lote.porCaducar
      ? CalendarPreviewStatus.expiring
      : lote.porAgotarse
      ? CalendarPreviewStatus.lowStock
      : CalendarPreviewStatus.healthy;
  final unit = lote.unidad ?? 'pza';
  return CalendarAlertPreview(
    lote.productoNombre ?? 'Producto',
    etiquetaPresentacion(lote.presentacion, lote.contenidoEnvase, unit),
    describirExistencia(
      cantidad: lote.cantidad,
      unidad: unit,
      presentacion: lote.presentacion,
      contenidoEnvase: lote.contenidoEnvase,
    ),
    status,
    ProductThumbnailKind.placeholder,
    lotCode: lote.id == null ? 'Lote' : 'Lote #${lote.id}',
    loteId: lote.id,
    productoId: lote.productoId,
    cantidad: lote.cantidad,
    unidad: unit,
    imagePath: lote.productoImagen,
    alarmaActiva: lote.alarmaActiva,
    horaAviso: lote.horaAviso,
    porAgotarse: lote.porAgotarse,
    stockTotal: lote.stockTotalProducto,
    stockMinimo: lote.stockMinimo,
    storageZone: lote.zonaAlmacenamiento,
    category: lote.categoriaNombre,
    fechaCaducidad: lote.fechaCaducidad,
  );
}

const calendarPreviewMonths = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

// Formatea una fecha
String calendarPreviewDateLabel(DateTime day) =>
    '${day.day} de ${calendarPreviewMonths[day.month - 1].toLowerCase()} de ${day.year}';
