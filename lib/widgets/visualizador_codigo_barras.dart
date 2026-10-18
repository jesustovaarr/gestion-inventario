import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/tema_alacena.dart';

// Algoritmos y lógica de codificación de códigos de barras
// Genera secuencias binarias de módulos ('1' = barra negra, '0' = espacio en blanco)
class GeneradorCodigoBarras {
  // Patrones L-code EAN-13 (7 módulos por dígito)
  static const List<String> _eanL = [
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011',
  ];

  // Patrones G-code EAN-13 (7 módulos por dígito)
  static const List<String> _eanG = [
    '0100111', '0110011', '0011011', '0100001', '0011101',
    '0111001', '0000101', '0010001', '0001001', '0010111',
  ];

  // Patrones R-code EAN-13 (7 módulos por dígito)
  static const List<String> _eanR = [
    '1110010', '1100110', '1101100', '1000010', '1011100',
    '1001110', '1010000', '1000100', '1001000', '1110100',
  ];

  // Tabla de paridad según el primer dígito en EAN-13
  static const List<String> _eanParidad = [
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
    'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL',
  ];

  // Calcula el dígito verificador estándar EAN
  static int calcularChecksumEan(String doceDigitos) {
    int suma = 0;
    for (int i = 0; i < doceDigitos.length && i < 12; i++) {
      final d = int.tryParse(doceDigitos[i]) ?? 0;
      suma += (i % 2 == 0) ? d : (d * 3);
    }
    final mod = suma % 10;
    return mod == 0 ? 0 : 10 - mod;
  }

  // Verifica si una cadena de texto es un código EAN-13 válido
  static bool esEan13(String codigo) {
    final limpio = codigo.replaceAll(RegExp(r'\D'), '');
    if (limpio.length != 12 && limpio.length != 13) return false;
    if (limpio.length == 13) {
      final checkEsperado = calcularChecksumEan(limpio.substring(0, 12));
      final checkReal = int.tryParse(limpio[12]);
      return checkReal == checkEsperado;
    }
    return true;
  }

  // Genera la secuencia binaria de 95 módulos para EAN-13
  static String? generarBitsEan13(String codigo) {
    String str = codigo.replaceAll(RegExp(r'\D'), '');
    if (str.length == 12) {
      str += calcularChecksumEan(str).toString();
    }
    if (str.length != 13) return null;

    final d1 = int.parse(str[0]);
    final paridad = _eanParidad[d1];
    final buffer = StringBuffer();

    // Guard izquierdo
    buffer.write('101');

    // 6 dígitos izquierdos 
    for (int i = 1; i <= 6; i++) {
      final d = int.parse(str[i]);
      buffer.write(paridad[i - 1] == 'L' ? _eanL[d] : _eanG[d]);
    }

    // Guard central
    buffer.write('01010');

    // 6 dígitos derechos
    for (int i = 7; i <= 12; i++) {
      final d = int.parse(str[i]);
      buffer.write(_eanR[d]);
    }

    // Guard derecho
    buffer.write('101');

    return buffer.toString();
  }

  // 107 patrones estándar Code 128
  static const List<String> _code128Patterns = [
    '11011001100', '11001101100', '11001100110', '10010011000', '10010001100',
    '10001001100', '10011001000', '10011000100', '10001100100', '11001001000',
    '11001000100', '11000100100', '10110011100', '10011011100', '10011001110',
    '10111001100', '10011101100', '10011100110', '11001110010', '11001011100',
    '11001001110', '11011100100', '11001110100', '11101101110', '11101001100',
    '11100101100', '11100100110', '11101100100', '11100110100', '11100110010',
    '11011011000', '11011000110', '11000110110', '10100011000', '10001011000',
    '10001000110', '10110001000', '10001101000', '10001100010', '11010001000',
    '11000101000', '11000100010', '10110111000', '10110001110', '10001101110',
    '10111011000', '10111000110', '10001110110', '11101110110', '11010001110',
    '11000101110', '11011101000', '11011100010', '11011101110', '11101011000',
    '11101000110', '11100010110', '11101101000', '11101100010', '11100011010',
    '11101111010', '11001000010', '11110001010', '10100110000', '10100001100',
    '10010110000', '10010000110', '10000101100', '10000100110', '10110010000',
    '10110000100', '10011010000', '10011000010', '10000110100', '10000110010',
    '11000010010', '11001010000', '11110111010', '11000010100', '10001111010',
    '10100111100', '10010111100', '10010011110', '10111100100', '10011110100',
    '10011110010', '11110100100', '11110010100', '11110010010', '11011011110',
    '11011110110', '11110110110', '10101111000', '10100011110', '10001011110',
    '10111101000', '10111100010', '11110101000', '11110100010', '10111011110',
    '10111101110', '11101011110', '11110101110', '11010000100', '11010010000',
    '11010011100', '1100011101011',
  ];

  // Genera bits usando Code 128
  static String generarBitsCode128(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return '';

    final buffer = StringBuffer();
    // Start B = índice 104
    buffer.write(_code128Patterns[104]);
    int checksum = 104;

    for (int i = 0; i < limpio.length; i++) {
      final codeUnit = limpio.codeUnitAt(i);
      final index = (codeUnit >= 32 && codeUnit <= 126) ? (codeUnit - 32) : 0;
      buffer.write(_code128Patterns[index]);
      checksum += index * (i + 1);
    }

    final checkIndex = checksum % 103;
    buffer.write(_code128Patterns[checkIndex]);
    // Stop = índice 106
    buffer.write(_code128Patterns[106]);

    return buffer.toString();
  }

  // Genera los bits correspondientes para cualquier código
  static String generarBits(String codigo) {
    final limpio = codigo.trim();
    if (limpio.isEmpty) return '';

    if (esEan13(limpio)) {
      final eanBits = generarBitsEan13(limpio);
      if (eanBits != null) return eanBits;
    }

    return generarBitsCode128(limpio);
  }

  // Retorna la simbología detectada
  static String tipoSimbologia(String codigo) {
    return esEan13(codigo.trim()) ? 'EAN-13' : 'Code 128';
  }

  // Da formato legible con espaciado a los dígitos.
  static String formatear(String codigo) {
    final limpio = codigo.trim();
    if (esEan13(limpio)) {
      var ean = limpio.replaceAll(RegExp(r'\D'), '');
      if (ean.length == 12) {
        ean += calcularChecksumEan(ean).toString();
      }
      if (ean.length == 13) {
        return '${ean[0]}  ${ean.substring(1, 7)}  ${ean.substring(7, 13)}';
      }
    }
    return limpio;
  }
}

// CustomPainter para dibujar barras nítidas sin aliasing borroso
class PintorCodigoBarras extends CustomPainter {
  final String bits;
  final Color colorBarras;
  final Color colorFondo;

  const PintorCodigoBarras({
    required this.bits,
    this.colorBarras = Colors.black,
    this.colorFondo = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bits.isEmpty) return;

    // Pintar fondo
    final paintFondo = Paint()
      ..color = colorFondo
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paintFondo);

    // Margen de zona de silencio en módulos
    const quietZoneModulos = 8;
    final totalModulos = bits.length + (quietZoneModulos * 2);
    final anchoModulo = size.width / totalModulos;

    final paintBarra = Paint()
      ..color = colorBarras
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;

    double x = quietZoneModulos * anchoModulo;
    for (int i = 0; i < bits.length; i++) {
      if (bits[i] == '1') {
        final rect = Rect.fromLTWH(x, 0, anchoModulo + 0.1, size.height);
        canvas.drawRect(rect, paintBarra);
      }
      x += anchoModulo;
    }
  }

  @override
  bool shouldRepaint(covariant PintorCodigoBarras oldDelegate) {
    return oldDelegate.bits != bits ||
        oldDelegate.colorBarras != colorBarras ||
        oldDelegate.colorFondo != colorFondo;
  }
}

// Widget visual del código de barras
// Renderiza las barras con contraste óptimo y los números legibles en la parte inferior
class VisualizadorCodigoBarras extends StatelessWidget {
  final String codigo;
  final double altura;
  final double? ancho;
  final bool mostrarTexto;
  final Color colorBarras;
  final Color colorFondo;
  final EdgeInsetsGeometry padding;

  const VisualizadorCodigoBarras({
    super.key,
    required this.codigo,
    this.altura = 75,
    this.ancho,
    this.mostrarTexto = true,
    this.colorBarras = Colors.black,
    this.colorFondo = Colors.white,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final bits = GeneradorCodigoBarras.generarBits(codigo);
    final textoFormateado = GeneradorCodigoBarras.formatear(codigo);

    if (bits.isEmpty) {
      return Container(
        height: altura,
        width: ancho,
        alignment: Alignment.center,
        padding: padding,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Código inválido o vacío',
          style: TextStyle(fontSize: 12, color: PantryColors.muted),
        ),
      );
    }

    return Container(
      width: ancho,
      padding: padding,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PantryColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: altura,
            width: double.infinity,
            child: CustomPaint(
              painter: PintorCodigoBarras(
                bits: bits,
                colorBarras: colorBarras,
                colorFondo: colorFondo,
              ),
            ),
          ),
          if (mostrarTexto) ...[
            const SizedBox(height: 8),
            Text(
              textoFormateado,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Diálogo modal interactivo para inspeccionar y escanear el código de barras en pantalla completa
class VisualizadorCodigoBarrasModal extends StatelessWidget {
  final String codigo;
  final String? nombreProducto;

  const VisualizadorCodigoBarrasModal({
    super.key,
    required this.codigo,
    this.nombreProducto,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String codigo,
    String? nombreProducto,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => VisualizadorCodigoBarrasModal(
        codigo: codigo,
        nombreProducto: nombreProducto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipo = GeneradorCodigoBarras.tipoSimbologia(codigo);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: PantryColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PantryColors.greenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: PantryColors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Código de barras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PantryColors.ink,
                        ),
                      ),
                      Text(
                        'Simbología $tipo · Escaneable en caja o alacena',
                        style: const TextStyle(
                          fontSize: 11,
                          color: PantryColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (nombreProducto != null && nombreProducto!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: PantryColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: PantryColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nombreProducto!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PantryColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            // Tarjeta de alto contraste con el código dibujado
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PantryColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  VisualizadorCodigoBarras(
                    codigo: codigo,
                    altura: 90,
                    mostrarTexto: true,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('btn_copiar_codigo_modal'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar número'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PantryColors.ink,
                      side: const BorderSide(color: PantryColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Código "$codigo" copiado al portapapeles'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: PantryColors.green,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('btn_cerrar_codigo_modal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PantryColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Listo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
