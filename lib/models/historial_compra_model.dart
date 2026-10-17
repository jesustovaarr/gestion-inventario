class HistorialCompra {
  final int? id;
  final int productoId;
  final int tiendaId;
  final double cantidad;
  final double precioUnitario;
  final String fechaCompra;
  final String? productoNombre;
  final String? tiendaNombre;

  const HistorialCompra({
    this.id,
    required this.productoId,
    required this.tiendaId,
    required this.cantidad,
    required this.precioUnitario,
    required this.fechaCompra,
    this.productoNombre,
    this.tiendaNombre,
  });

  // Getters
  int? get idCompra => id;
  int get idProducto => productoId;
  int get idTienda => tiendaId;
  double get totalGasto => cantidad * precioUnitario;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'producto_id': productoId,
      'tienda_id': tiendaId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'fecha_compra': fechaCompra,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory HistorialCompra.fromMap(Map<String, dynamic> map) {
    return HistorialCompra(
      id: (map['id'] ?? map['id_compra']) as int?,
      productoId: (map['producto_id'] ?? map['id_producto']) as int? ?? 0,
      tiendaId: (map['tienda_id'] ?? map['id_tienda']) as int? ?? 0,
      cantidad: (map['cantidad'] is num)
          ? (map['cantidad'] as num).toDouble()
          : 0.0,
      precioUnitario: (map['precio_unitario'] is num)
          ? (map['precio_unitario'] as num).toDouble()
          : 0.0,
      fechaCompra: (map['fecha_compra'] ?? '') as String,
      productoNombre: map['producto_nombre'] as String?,
      tiendaNombre: map['tienda_nombre'] as String?,
    );
  }
}
