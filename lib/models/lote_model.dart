import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';

class Lote {
  final int? id;
  final int productoId;
  final double cantidad;
  final String fechaCaducidad;
  final int? alarmaId;
  final String horaAviso;
  final int alarmaActiva; // 1 para activa y 0 para inactiva
  final String? productoNombre;
  final String? productoImagen;
  final String? unidad;

  const Lote({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.fechaCaducidad,
    this.alarmaId,
    this.alarmaActiva = 1,
    this.horaAviso = '09:00 AM',
    this.productoNombre,
    this.productoImagen,
    this.unidad,
    this.presentacion = PresentacionCompra.granel,
    this.contenidoEnvase = 1,
  });

  // Getters
  final PresentacionCompra presentacion;
  final double contenidoEnvase;
  int? get idLote => id;
  int get idProducto => productoId;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'producto_id': productoId,
      'cantidad': cantidad,
      'fecha_caducidad': fechaCaducidad,
      'alarma_id': alarmaId,
      'alarma_activa': alarmaActiva,
      'hora_aviso': horaAviso,
      'presentacion': presentacion.name,
      'contenido_envase': contenidoEnvase,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Lote.fromMap(Map<String, dynamic> map) {
    return Lote(
      id: (map['id'] ?? map['id_lote']) as int?,
      productoId: (map['producto_id'] ?? map['id_producto']) as int? ?? 0,
      cantidad: normalizarCantidad((map['cantidad'] as num?) ?? 0),
      fechaCaducidad: (map['fecha_caducidad'] ?? '') as String,
      alarmaId: map['alarma_id'] as int?,
      alarmaActiva: map['alarma_activa'] as int? ?? 1,
      horaAviso: map['hora_aviso'] as String? ?? '09:00 AM',
      presentacion: PresentacionCompra.leer(map['presentacion'] as String?),
      contenidoEnvase: (map['contenido_envase'] as num?)?.toDouble() ?? 1,
      productoNombre: map['producto_nombre'] as String?,
      productoImagen: map['producto_imagen'] as String?,
      unidad: map['unidad'] as String?,
    );
  }

  Lote copyWith({
    double? cantidad,
    String? fechaCaducidad,
    int? alarmaActiva,
    String? horaAviso,
    PresentacionCompra? presentacion,
    double? contenidoEnvase,
  }) => Lote(
    id: id,
    productoId: productoId,
    cantidad: cantidad ?? this.cantidad,
    fechaCaducidad: fechaCaducidad ?? this.fechaCaducidad,
    alarmaId: alarmaId,
    alarmaActiva: alarmaActiva ?? this.alarmaActiva,
    horaAviso: horaAviso ?? this.horaAviso,
    presentacion: presentacion ?? this.presentacion,
    contenidoEnvase: contenidoEnvase ?? this.contenidoEnvase,
    productoNombre: productoNombre,
    productoImagen: productoImagen,
    unidad: unidad,
  );

  int get diasParaCaducar {
    try {
      final caducidad = DateTime.parse(fechaCaducidad);
      final hoy = DateTime.now();
      final fechaSinHora = DateTime(hoy.year, hoy.month, hoy.day);
      return caducidad.difference(fechaSinHora).inDays;
    } catch (_) {
      return 0;
    }
  }

  bool get estaCaducado => diasParaCaducar < 0;
  bool get caducaHoy => diasParaCaducar == 0;
  bool get porCaducar => diasParaCaducar >= 0 && diasParaCaducar <= 3;
}
