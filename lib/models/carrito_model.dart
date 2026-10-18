import '../utils/presentaciones.dart';

class CarritoItem {
  final int? id;
  final int productoId;
  final double cantidadAComprar;
  final String? productoNombre;
  final String? unidadMedida;
  final String? imagen;
  final double? stockMinimo;
  final double? stockActual;

  const CarritoItem({
    this.id,
    required this.productoId,
    this.cantidadAComprar = 1.0,
    this.productoNombre,
    this.unidadMedida,
    this.imagen,
    this.stockMinimo,
    this.stockActual,
    this.presentacion = PresentacionCompra.granel,
    this.numeroEnvases = 1,
    this.contenidoEnvase = 1,
    this.precioCentavos,
    this.fechaCaducidad,
  });

  // Getters
  final PresentacionCompra presentacion;
  final int numeroEnvases;
  final double contenidoEnvase;
  final int? precioCentavos;
  final String? fechaCaducidad;
  int? get idCarrito => id;
  int get idProducto => productoId;
  double get cantidadComprar => cantidadAComprar;
  String? get unidad => unidadMedida;
  String get key => productoId.toString();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'producto_id': productoId,
      'cantidad_a_comprar': cantidadAComprar,
      'presentacion': presentacion.name,
      'numero_envases': numeroEnvases,
      'contenido_envase': contenidoEnvase,
      'precio_envase_centavos': precioCentavos,
      'fecha_caducidad': fechaCaducidad,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory CarritoItem.fromMap(Map<String, dynamic> map) {
    return CarritoItem(
      id: (map['id'] ?? map['id_carrito']) as int?,
      productoId: (map['producto_id'] ?? map['id_producto']) as int? ?? 0,
      presentacion: PresentacionCompra.leer(map['presentacion'] as String?),
      numeroEnvases: (map['numero_envases'] as num?)?.toInt() ?? 1,
      contenidoEnvase: (map['contenido_envase'] as num?)?.toDouble() ?? 1,
      precioCentavos: (map['precio_envase_centavos'] as num?)?.toInt(),
      fechaCaducidad: map['fecha_caducidad'] as String?,
      cantidadAComprar:
          ((map['cantidad_a_comprar'] ?? map['cantidad_comprar']) is num)
          ? ((map['cantidad_a_comprar'] ?? map['cantidad_comprar']) as num)
                .toDouble()
          : 1.0,
      productoNombre: map['producto_nombre'] as String?,
      unidadMedida: (map['unidad_medida'] ?? map['unidad']) as String?,
      imagen: map['imagen'] as String?,
      stockMinimo: (map['stock_minimo'] is num)
          ? (map['stock_minimo'] as num).toDouble()
          : null,
      stockActual: (map['stock_actual'] is num)
          ? (map['stock_actual'] as num).toDouble()
          : null,
    );
  }

  CarritoItem copyWith({
    int? id,
    int? productoId,
    double? cantidadAComprar,
    String? productoNombre,
    String? unidadMedida,
    String? imagen,
    double? stockMinimo,
    double? stockActual,
  }) {
    return CarritoItem(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidadAComprar: cantidadAComprar ?? this.cantidadAComprar,
      productoNombre: productoNombre ?? this.productoNombre,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      imagen: imagen ?? this.imagen,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockActual: stockActual ?? this.stockActual,
      presentacion: presentacion,
      numeroEnvases: numeroEnvases,
      contenidoEnvase: contenidoEnvase,
      precioCentavos: precioCentavos,
      fechaCaducidad: fechaCaducidad,
    );
  }
}
