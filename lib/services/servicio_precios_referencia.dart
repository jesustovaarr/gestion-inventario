import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/datos_escaneo_producto.dart';
import '../utils/presentaciones.dart';

class ServicioPreciosReferencia {
  static ServicioPreciosReferencia? _instancia;
  factory ServicioPreciosReferencia() =>
      _instancia ??= ServicioPreciosReferencia._();

  ServicioPreciosReferencia._();

  // Constructor para inyección de datos en tests
  ServicioPreciosReferencia.conDatos(Map<String, dynamic> datos) {
    _cacheDatos = datos;
    _cargado = true;
  }

  Map<String, dynamic>? _cacheDatos;
  bool _cargado = false;

  Future<void> _asegurarCargado() async {
    if (_cargado) return;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/precios_referencia.json',
      );
      _cacheDatos = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cargado = true;
    } catch (_) {
      _cacheDatos = {};
      _cargado = true;
    }
  }

  // Busca si existe información directa del producto en el catálogo de referencia
  Future<DatosEscaneoProducto?> obtenerDatosPorCodigo(String codigo) async {
    await _asegurarCargado();
    final cleanCode = codigo.trim();
    final productos =
        _cacheDatos?['productos_por_codigo'] as Map<String, dynamic>?;

    if (productos != null && productos.containsKey(cleanCode)) {
      final item = productos[cleanCode] as Map<String, dynamic>;
      final presentacionStr = item['presentacion'] as String?;
      PresentacionCompra? presentacion;
      if (presentacionStr != null) {
        presentacion = PresentacionCompra.leer(presentacionStr);
      }

      return DatosEscaneoProducto(
        codigo: cleanCode,
        nombre: item['nombre'] as String?,
        categoria: item['categoria'] as String?,
        precioSugerido: (item['precio'] as num?)?.toDouble(),
        unidad: item['unidad'] as String?,
        presentacion: presentacion,
        contenidoEnvase: (item['contenido'] as num?)?.toDouble(),
      );
    }

    return null;
  }

  // Obtiene un precio estimado: primero por código de producto,
  // o de respaldo por la categoría del producto con escalado por volumen/contenido
  Future<double?> obtenerPrecio({
    required String codigo,
    String? categoria,
    double? contenido,
    String? unidad,
  }) async {
    await _asegurarCargado();
    final cleanCode = codigo.trim();

    // Buscar por código específico
    final productos =
        _cacheDatos?['productos_por_codigo'] as Map<String, dynamic>?;
    if (productos != null && productos.containsKey(cleanCode)) {
      final item = productos[cleanCode] as Map<String, dynamic>;
      final precio = (item['precio'] as num?)?.toDouble();
      if (precio != null && precio > 0) return precio;
    }

    // Respaldo por categoría general con escalado
    final categorias =
        _cacheDatos?['precios_por_categoria'] as Map<String, dynamic>?;
    if (categorias != null) {
      double? basePrecio;
      if (categoria != null && categorias.containsKey(categoria)) {
        basePrecio = (categorias[categoria] as num?)?.toDouble();
      }
      basePrecio ??= (categorias['Otros'] as num?)?.toDouble();

      if (basePrecio != null && basePrecio > 0) {
        if (contenido != null && contenido > 0 && unidad != null) {
          final u = unidad.trim().toLowerCase();
          if (u == 'l' || u == 'lt' || u == 'litro' || u == 'litros') {
            if (contenido == 1.0) {
              return basePrecio;
            } else if (contenido > 1.0) {
              return double.parse(
                (basePrecio * (1.0 + (contenido - 1.0) * 0.60))
                    .toStringAsFixed(2),
              );
            } else {
              return double.parse(
                (basePrecio * contenido * 1.25)
                    .clamp(8.0, 999.0)
                    .toStringAsFixed(2),
              );
            }
          } else if (u == 'ml') {
            final litros = contenido / 1000.0;
            if (litros >= 1.0) {
              return double.parse(
                (basePrecio * (1.0 + (litros - 1.0) * 0.60))
                    .toStringAsFixed(2),
              );
            } else {
              return double.parse(
                (basePrecio * (0.35 + litros * 0.65))
                    .clamp(10.0, 999.0)
                    .toStringAsFixed(2),
              );
            }
          } else if (u == 'kg' || u == 'kilo' || u == 'kilos') {
            if (contenido == 1.0) {
              return basePrecio;
            } else if (contenido > 1.0) {
              return double.parse(
                (basePrecio * (1.0 + (contenido - 1.0) * 0.70))
                    .toStringAsFixed(2),
              );
            } else {
              return double.parse(
                (basePrecio * contenido * 1.15)
                    .clamp(8.0, 999.0)
                    .toStringAsFixed(2),
              );
            }
          } else if (u == 'g' || u == 'gr' || u == 'gramos') {
            final kg = contenido / 1000.0;
            if (kg >= 1.0) {
              return double.parse(
                (basePrecio * (1.0 + (kg - 1.0) * 0.70))
                    .toStringAsFixed(2),
              );
            } else {
              return double.parse(
                (basePrecio * (0.30 + kg * 0.70))
                    .clamp(8.0, 999.0)
                    .toStringAsFixed(2),
              );
            }
          } else if (u == 'pza' || u == 'pieza' || u == 'piezas') {
            return double.parse((basePrecio * contenido).toStringAsFixed(2));
          }
        }
        return basePrecio;
      }
    }

    return null;
  }
}
