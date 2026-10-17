class Lote {
  final int? id;
  final int productoId;
  final double cantidad;
  final String fechaCaducidad;
  final int? alarmaId;
  final int alarmaActiva; // 1 para activa y 0 para inactiva
  final String? productoNombre;
  final String? unidad;

  const Lote({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.fechaCaducidad,
    this.alarmaId,
    this.alarmaActiva = 1,
    this.productoNombre,
    this.unidad,
  });

  // Getters
  int? get idLote => id;
  int get idProducto => productoId;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'producto_id': productoId,
      'cantidad': cantidad,
      'fecha_caducidad': fechaCaducidad,
      'alarma_id': alarmaId,
      'alarma_activa': alarmaActiva,
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
      cantidad: (map['cantidad'] is num)
          ? (map['cantidad'] as num).toDouble()
          : 0.0,
      fechaCaducidad: (map['fecha_caducidad'] ?? '') as String,
      alarmaId: map['alarma_id'] as int?,
      alarmaActiva: map['alarma_activa'] as int? ?? 1,
      productoNombre: map['producto_nombre'] as String?,
      unidad: map['unidad'] as String?,
    );
  }

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
