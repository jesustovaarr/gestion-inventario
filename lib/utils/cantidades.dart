/// Las cantidades del inventario usan milésimas de unidad.
/// Las operaciones en enteros evitan residuos como 0.000000099999.
const int escalaCantidad = 1000;
const double cantidadMaxima = 999999;

int cantidadEnMilesimas(num valor) => (valor * escalaCantidad).round();

double normalizarCantidad(num valor) {
  if (!valor.isFinite) return 0;
  return cantidadEnMilesimas(valor) / escalaCantidad;
}

bool cantidadValida(num valor, {bool permiteCero = false}) =>
    valor.isFinite &&
    valor <= cantidadMaxima &&
    (permiteCero ? valor >= 0 : valor > 0) &&
    (permiteCero || cantidadEnMilesimas(valor) > 0) &&
    (valor - normalizarCantidad(valor)).abs() < 1e-9;

/// Admite punto o coma decimal, sin exponentes ni más de tres decimales.
double? leerCantidad(String texto, {bool permiteCero = false}) {
  final limpio = texto.trim();
  if (!RegExp(r'^(?:\d+(?:[.,]\d{0,3})?|[.,]\d{1,3})$').hasMatch(limpio)) {
    return null;
  }
  final valor = double.tryParse(limpio.replaceAll(',', '.'));
  if (valor == null || !cantidadValida(valor, permiteCero: permiteCero)) {
    return null;
  }
  return normalizarCantidad(valor);
}

String formatearCantidad(num valor) {
  if (!valor.isFinite || valor < 0 || valor > cantidadMaxima) return '—';
  return normalizarCantidad(valor)
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'\.?0+$'), '');
}
