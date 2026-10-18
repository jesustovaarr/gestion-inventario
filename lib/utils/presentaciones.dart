import 'cantidades.dart';

enum PresentacionCompra {
  granel('A granel', 'a granel'),
  pieza('Pieza', 'piezas'),
  bolsa('Bolsa', 'bolsas'),
  botella('Botella', 'botellas'),
  lata('Lata', 'latas'),
  carton('Cartón', 'cartones'),
  caja('Caja', 'cajas'),
  paquete('Paquete', 'paquetes'),
  frasco('Frasco', 'frascos');

  const PresentacionCompra(this.singular, this.plural);
  final String singular;
  final String plural;
  bool get esEnvase => this != granel;
  String etiqueta(int cantidad) =>
      cantidad == 1 ? singular.toLowerCase() : plural;
  static PresentacionCompra leer(String? valor) =>
      values.firstWhere((p) => p.name == valor, orElse: () => granel);
}

String unidadVisible(String unidad) => unidad == 'lt' ? 'L' : unidad;

String etiquetaPresentacion(
  PresentacionCompra tipo,
  double contenido,
  String unidad,
) => tipo.esEnvase
    ? '${tipo.singular} de ${formatearContenido(contenido, unidad)}'
    : 'A granel · ${unidadVisible(unidad)}';

String formatearContenido(num cantidad, String unidad) {
  if (cantidad > 0 && cantidad < 1) {
    if (unidad == 'kg') return '${formatearCantidad(cantidad * 1000)} g';
    if (unidad == 'lt' || unidad == 'L') {
      return '${formatearCantidad(cantidad * 1000)} ml';
    }
  }
  return '${formatearCantidad(cantidad)} ${unidadVisible(unidad)}';
}

String describirExistencia({
  required double cantidad,
  required String unidad,
  required PresentacionCompra presentacion,
  required double contenidoEnvase,
}) {
  if (cantidad <= 0) return 'Sin existencias';
  if (!presentacion.esEnvase || !cantidadValida(contenidoEnvase)) {
    return '${formatearContenido(cantidad, unidad)} restantes';
  }
  final total = cantidadEnMilesimas(cantidad);
  final porEnvase = cantidadEnMilesimas(contenidoEnvase);
  final completos = total ~/ porEnvase;
  final restante = (total % porEnvase) / escalaCantidad;
  final formato =
      '${presentacion.singular.toLowerCase()} de ${formatearContenido(contenidoEnvase, unidad)}';
  if (completos == 0) {
    return '${formatearContenido(restante, unidad)} restantes ($formato)';
  }
  final envases =
      '$completos ${presentacion.etiqueta(completos)} de ${formatearContenido(contenidoEnvase, unidad)}';
  return restante == 0
      ? envases
      : '$envases + ${formatearContenido(restante, unidad)}';
}
