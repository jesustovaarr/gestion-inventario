import '../utils/cantidades.dart';
import 'lote_model.dart';

enum EstadoProducto { caducado, agotado, porCaducar, porAgotarse, enOrden }

class Producto {
  final int? id;
  final String nombre;
  final double? precio;
  final String? proximaCaducidad;
  final int? primerLoteId;
  final double cantidadPrimerLote;
  final String imagen;
  final String? zonaAlmacenamiento;
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
    this.precio,
    this.codigo,
    this.presentacion = 'granel',
    this.contenidoEnvase = 1,
    this.proximaCaducidad,
    this.primerLoteId,
    this.cantidadPrimerLote = 0,
    this.imagen = '',
    this.zonaAlmacenamiento,
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
    this.lotesActivos = const [],
  });

  // Getters
  final List<Lote> lotesActivos;
  final String? codigo;
  final String presentacion;
  final double contenidoEnvase;
  int? get idProducto => id;
  int get idCategoria => categoriaId;
  String get unidad => unidadMedida;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'precio': precio,
      'codigo': codigo,
      'presentacion': presentacion,
      'contenido_envase': contenidoEnvase,
      'imagen': imagen,
      'zona_almacenamiento': zonaAlmacenamiento,
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
    final stock = normalizarCantidad((map['stock_actual'] as num?) ?? 0);
    final minStock = (map['stock_minimo'] is num)
        ? (map['stock_minimo'] as num).toDouble()
        : 1.0;

    final tieneCaducado =
        (map['tiene_caducado'] == 1 || map['tiene_caducado'] == true);
    final tienePorCaducar =
        (map['tiene_por_caducar'] == 1 || map['tiene_por_caducar'] == true);

    // Calcular estado
    EstadoProducto estadoCalc;
    if (stock == 0) {
      estadoCalc = EstadoProducto.agotado;
    } else if (tieneCaducado) {
      estadoCalc = EstadoProducto.caducado;
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
      precio: (map['precio'] as num?)?.toDouble(),
      codigo: map['codigo'] as String?,
      presentacion: map['presentacion'] as String? ?? 'granel',
      contenidoEnvase: (map['contenido_envase'] as num?)?.toDouble() ?? 1,
      proximaCaducidad: stock > 0 ? map['proxima_caducidad'] as String? : null,
      primerLoteId: stock > 0 ? map['primer_lote_id'] as int? : null,
      cantidadPrimerLote: normalizarCantidad(
        (map['cantidad_primer_lote'] as num?) ?? 0,
      ),
      imagen: map['imagen'] as String? ?? '',
      zonaAlmacenamiento: map['zona_almacenamiento'] as String?,
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
    double? precio,
    String? codigo,
    String? presentacion,
    double? contenidoEnvase,
    String? imagen,
    String? zonaAlmacenamiento,
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
    List<Lote>? lotesActivos,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      codigo: codigo ?? this.codigo,
      presentacion: presentacion ?? this.presentacion,
      contenidoEnvase: contenidoEnvase ?? this.contenidoEnvase,
      proximaCaducidad: proximaCaducidad,
      primerLoteId: primerLoteId,
      cantidadPrimerLote: cantidadPrimerLote,
      imagen: imagen ?? this.imagen,
      zonaAlmacenamiento: zonaAlmacenamiento ?? this.zonaAlmacenamiento,
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
      lotesActivos: lotesActivos ?? this.lotesActivos,
    );
  }
}
