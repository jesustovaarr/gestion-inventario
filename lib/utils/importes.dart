const int precioMaximoCentavos = 99999999;

int? leerPrecioCentavos(String texto) {
  final value = texto.trim().replaceAll(',', '.');
  if (!RegExp(r'^(?:\d+(?:\.\d{0,2})?|\.\d{1,2})$').hasMatch(value)) {
    return null;
  }
  final parts = value.split('.');
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first);
  if (whole == null || whole > 999999) return null;
  final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  return whole * 100 + cents;
}

String formatearImporte(int centavos) =>
    '${centavos ~/ 100}.${(centavos % 100).toString().padLeft(2, '0')}';
