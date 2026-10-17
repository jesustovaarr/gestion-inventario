enum EstadoProducto {
  caducado,
  agotado,
  porCaducar,
  porAgotarse,
  enOrden,
}

class Producto {
  final int? id;
  final String nombre;
  final String imagen;
  final String unidadMedida;
  final double stockMinimo;
  final int categoriaId;
  final int? ultimaTiendaId;
  final String? categoriaNombre;
  final String? ultimaTiendaNombre;
  final double stockActual;
  final EstadoProducto estado;
  final bool tieneLoteCaducado;
  final bool tieneLotePorCaducar;

  const Producto({
    this.id,
    required this.nombre,
    this.imagen = '',
    this.unidadMedida = 'pza',
    required this.stockMinimo,
    required this.categoriaId,
    this.ultimaTiendaId,
    this.categoriaNombre,
    this.ultimaTiendaNombre,
    this.stockActual = 0.0,
    this.estado = EstadoProducto.agotado,
    this.tieneLoteCaducado = false,
    this.tieneLotePorCaducar = false,
  });

  // Getters
  int? get idProducto => id;
  int get idCategoria => categoriaId;
  String get unidad => unidadMedida;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'imagen': imagen,
      'unidad_medida': unidadMedida,
      'stock_minimo': stockMinimo,
      'categoria_id': categoriaId,
      'ultima_tienda_id': ultimaTiendaId,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    final stock = (map['stock_actual'] is num)
        ? (map['stock_actual'] as num).toDouble()
        : 0.0;
    final minStock = (map['stock_minimo'] is num)
        ? (map['stock_minimo'] as num).toDouble()
        : 1.0;

    final tieneCaducado = (map['tiene_caducado'] == 1 || map['tiene_caducado'] == true);
    final tienePorCaducar = (map['tiene_por_caducar'] == 1 || map['tiene_por_caducar'] == true);

    // Calcular estado
    EstadoProducto estadoCalc;
    if (tieneCaducado) {
      estadoCalc = EstadoProducto.caducado;
    } else if (stock == 0.0) {
      estadoCalc = EstadoProducto.agotado;
    } else if (tienePorCaducar) {
      estadoCalc = EstadoProducto.porCaducar;
    } else if (stock > 0.0 && stock <= minStock) {
      estadoCalc = EstadoProducto.porAgotarse;
    } else {
      estadoCalc = EstadoProducto.enOrden;
    }

    return Producto(
      id: (map['id'] ?? map['id_producto']) as int?,
      nombre: map['nombre'] as String? ?? '',
      imagen: map['imagen'] as String? ?? '',
      unidadMedida: (map['unidad_medida'] ?? map['unidad']) as String? ?? 'pza',
      stockMinimo: minStock,
      categoriaId: (map['categoria_id'] ?? map['id_categoria']) as int? ?? 1,
      ultimaTiendaId: (map['ultima_tienda_id'] ?? map['id_tienda']) as int?,
      categoriaNombre: map['categoria_nombre'] as String?,
      ultimaTiendaNombre: map['ultima_tienda_nombre'] as String?,
      stockActual: stock,
      estado: estadoCalc,
      tieneLoteCaducado: tieneCaducado,
      tieneLotePorCaducar: tienePorCaducar,
    );
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? imagen,
    String? unidadMedida,
    double? stockMinimo,
    int? categoriaId,
    int? ultimaTiendaId,
    String? categoriaNombre,
    String? ultimaTiendaNombre,
    double? stockActual,
    EstadoProducto? estado,
    bool? tieneLoteCaducado,
    bool? tieneLotePorCaducar,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      imagen: imagen ?? this.imagen,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      ultimaTiendaId: ultimaTiendaId ?? this.ultimaTiendaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      ultimaTiendaNombre: ultimaTiendaNombre ?? this.ultimaTiendaNombre,
      stockActual: stockActual ?? this.stockActual,
      estado: estado ?? this.estado,
      tieneLoteCaducado: tieneLoteCaducado ?? this.tieneLoteCaducado,
      tieneLotePorCaducar: tieneLotePorCaducar ?? this.tieneLotePorCaducar,
    );
  }
}
