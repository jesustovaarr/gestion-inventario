class Tienda {
  final int? id;
  final String nombre;
  final String? ubicacion;
  final int tipoTiendaId;
  final String? tipoTiendaNombre;
  final int totalCompras;

  const Tienda({
    this.id,
    required this.nombre,
    this.ubicacion,
    this.tipoTiendaId = 1,
    this.tipoTiendaNombre,
    this.totalCompras = 0,
  });

  int? get idTienda => id;
  String? get direccion => ubicacion;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'ubicacion': ubicacion,
      'tipo_tienda_id': tipoTiendaId,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Tienda.fromMap(Map<String, dynamic> map) {
    return Tienda(
      id: (map['id'] ?? map['id_tienda']) as int?,
      nombre: map['nombre'] as String? ?? '',
      ubicacion: (map['ubicacion'] ?? map['direccion']) as String?,
      tipoTiendaId: map['tipo_tienda_id'] as int? ?? 1,
      tipoTiendaNombre: map['tipo_tienda_nombre'] as String?,
      totalCompras: (map['total_compras'] is num)
          ? (map['total_compras'] as num).toInt()
          : 0,
    );
  }

  Tienda copyWith({
    int? id,
    String? nombre,
    String? ubicacion,
    int? tipoTiendaId,
    String? tipoTiendaNombre,
    int? totalCompras,
  }) {
    return Tienda(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      tipoTiendaId: tipoTiendaId ?? this.tipoTiendaId,
      tipoTiendaNombre: tipoTiendaNombre ?? this.tipoTiendaNombre,
      totalCompras: totalCompras ?? this.totalCompras,
    );
  }
}
