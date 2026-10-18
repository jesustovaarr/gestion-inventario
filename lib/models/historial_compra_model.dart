import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';

class HistorialCompra {
  final int? id;
  final int? compraId;
  final int productoId;
  final int tiendaId;
  final double cantidad;
  final double precioUnitario;
  final String fechaCompra;
  final String? productoNombre;
  final String? tiendaNombre;
  final String unidadMedida;
  final String? imagen;
  final String? fechaCaducidad;
  final PresentacionCompra presentacion;
  final int numeroEnvases;
  final double contenidoEnvase;
  final int? precioEnvaseCentavos;
  final bool precioRegistrado;

  const HistorialCompra({
    this.id,
    this.compraId,
    required this.productoId,
    required this.tiendaId,
    required this.cantidad,
    required this.precioUnitario,
    required this.fechaCompra,
    this.productoNombre,
    this.tiendaNombre,
    this.unidadMedida = 'pza',
    this.imagen,
    this.fechaCaducidad,
    this.presentacion = PresentacionCompra.granel,
    this.numeroEnvases = 1,
    this.contenidoEnvase = 1,
    this.precioEnvaseCentavos,
    this.precioRegistrado = true,
  });

  // Getters
  int? get idCompra => id;
  int get idProducto => productoId;
  int get idTienda => tiendaId;
  double get totalGasto => cantidad * precioUnitario;
  int? get subtotalCentavos =>
      precioEnvaseCentavos != null && presentacion.esEnvase
      ? numeroEnvases * precioEnvaseCentavos!
      : precioRegistrado
      ? (totalGasto * 100).round()
      : null;

  String get descripcionCantidad => presentacion.esEnvase
      ? '$numeroEnvases ${presentacion.etiqueta(numeroEnvases)} de ${formatearContenido(contenidoEnvase, unidadMedida)}'
      : '${formatearCantidad(cantidad)} ${unidadVisible(unidadMedida)}';

  int? get precioVisibleCentavos => presentacion.esEnvase
      ? precioEnvaseCentavos ??
            (precioRegistrado
                ? (precioUnitario * contenidoEnvase * 100).round()
                : null)
      : precioRegistrado
      ? (precioUnitario * 100).round()
      : null;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'producto_id': productoId,
      'tienda_id': tiendaId,
      'cantidad': cantidad,
      'precio_unitario': precioRegistrado ? precioUnitario : null,
      'fecha_compra': fechaCompra,
      'compra_id': compraId,
      'presentacion': presentacion.name,
      'numero_envases': numeroEnvases,
      'contenido_envase': contenidoEnvase,
      'precio_envase_centavos': precioEnvaseCentavos,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory HistorialCompra.fromMap(Map<String, dynamic> map) {
    return HistorialCompra(
      id: (map['id'] ?? map['id_compra']) as int?,
      compraId: map['compra_id'] as int?,
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
      unidadMedida: map['unidad_medida'] as String? ?? 'pza',
      imagen: map['imagen'] as String?,
      fechaCaducidad: map['fecha_caducidad'] as String?,
      presentacion: PresentacionCompra.leer(map['presentacion'] as String?),
      numeroEnvases: (map['numero_envases'] as num?)?.toInt() ?? 1,
      contenidoEnvase: (map['contenido_envase'] as num?)?.toDouble() ?? 1,
      precioEnvaseCentavos: (map['precio_envase_centavos'] as num?)?.toInt(),
      precioRegistrado: map['precio_unitario'] is num,
    );
  }
}
