import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
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
  empty(
    'Sin existencia',
    Icons.inventory_2_outlined,
    Color(0xFF526C76),
    Color(0xFFE7EEF0),
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
