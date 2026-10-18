import '../utils/presentaciones.dart';

// Modelo de datos que encapsula el resultado del escaneo y resolución de un código de barras
class DatosEscaneoProducto {
  final String codigo;
  final String? nombre;
  final String? marca;
  final String? categoria;
  final PresentacionCompra? presentacion;
  final double? contenidoEnvase;
  final String? unidad;
  final double? precioSugerido;
  final String? imagenUrl;
  final bool yaExisteEnInventario;
  final int? productoExistenteId;
  final String? nombreExistente;

  const DatosEscaneoProducto({
    required this.codigo,
    this.nombre,
    this.marca,
    this.categoria,
    this.presentacion,
    this.contenidoEnvase,
    this.unidad,
    this.precioSugerido,
    this.imagenUrl,
    this.yaExisteEnInventario = false,
    this.productoExistenteId,
    this.nombreExistente,
  });

  DatosEscaneoProducto copyWith({
    String? codigo,
    String? nombre,
    String? marca,
    String? categoria,
    PresentacionCompra? presentacion,
    double? contenidoEnvase,
    String? unidad,
    double? precioSugerido,
    String? imagenUrl,
    bool? yaExisteEnInventario,
    int? productoExistenteId,
    String? nombreExistente,
  }) {
    return DatosEscaneoProducto(
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      categoria: categoria ?? this.categoria,
      presentacion: presentacion ?? this.presentacion,
      contenidoEnvase: contenidoEnvase ?? this.contenidoEnvase,
      unidad: unidad ?? this.unidad,
      precioSugerido: precioSugerido ?? this.precioSugerido,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      yaExisteEnInventario: yaExisteEnInventario ?? this.yaExisteEnInventario,
      productoExistenteId: productoExistenteId ?? this.productoExistenteId,
      nombreExistente: nombreExistente ?? this.nombreExistente,
    );
  }
}
