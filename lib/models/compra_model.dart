import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';
import 'historial_compra_model.dart';

class ArticuloCompra {
  const ArticuloCompra({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitarioCentavos,
    required this.fechaCaducidad,
    this.presentacion = PresentacionCompra.granel,
    this.numeroEnvases = 1,
    this.contenidoEnvase = 1,
  });
  final int productoId;
  final double cantidad;
  final int precioUnitarioCentavos;
  final String fechaCaducidad;
  final PresentacionCompra presentacion;
  final int numeroEnvases;
  final double contenidoEnvase;
  String get key => productoId.toString();
  // El precio de un envasado corresponde a un envase. A granel es por kg, L, etc.
  double get precioPorUnidadInventario =>
      precioUnitarioCentavos /
      100 /
      (presentacion.esEnvase ? contenidoEnvase : 1);
  int get subtotalCentavos => presentacion.esEnvase
      ? numeroEnvases * precioUnitarioCentavos
      : (cantidadEnMilesimas(cantidad) * precioUnitarioCentavos + 500) ~/
            escalaCantidad;
}

class CompraGuardada {
  const CompraGuardada({
    required this.id,
    required this.totalCentavos,
    required this.articulos,
  });
  final int id;
  final int totalCentavos;
  final int articulos;
}

/// Una compra completa, o un registro individual anterior al uso de recibos.
class CompraEnHistorial {
  CompraEnHistorial({
    required this.clave,
    this.id,
    required this.tiendaId,
    required this.tiendaNombre,
    required this.fechaCompra,
    required this.totalCentavos,
    required List<HistorialCompra> articulos,
  }) : articulos = List.unmodifiable(articulos);

  final String clave;
  final int? id;
  final int tiendaId;
  final String tiendaNombre;
  final String fechaCompra;
  final int? totalCentavos;
  final List<HistorialCompra> articulos;
}
