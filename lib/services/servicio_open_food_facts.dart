import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/datos_escaneo_producto.dart';
import '../utils/presentaciones.dart';

class ServicioOpenFoodFacts {
  final http.Client _client;

  ServicioOpenFoodFacts({http.Client? client})
      : _client = client ?? http.Client();

  // Consulta Open Food Facts por el código de barras y devuelve datos estandarizados
  Future<DatosEscaneoProducto?> consultarCodigo(String codigo) async {
    final cleanCode = codigo.trim();
    if (cleanCode.isEmpty) return null;

    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$cleanCode.json',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'GestionInventarioAlacena/1.0 (contacto@alacena.local)',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1 || data['product'] == null) {
        return null;
      }

      final product = data['product'] as Map<String, dynamic>;
      return _parsearProducto(cleanCode, product);
    } catch (_) {
      // Si no hay internet, timeout o error de parseo, retornamos null sin romper la app
      return null;
    }
  }

  DatosEscaneoProducto _parsearProducto(
    String codigo,
    Map<String, dynamic> raw,
  ) {
    final rawName = (raw['product_name_es'] as String?)?.trim() ??
        (raw['product_name'] as String?)?.trim() ??
        '';
    final brand = (raw['brands'] as String?)?.trim() ?? '';
    final rawQuantity = (raw['quantity'] as String?)?.trim() ?? '';
    final imageUrl = (raw['image_front_url'] as String?)?.trim() ??
        (raw['image_url'] as String?)?.trim();

    final categoria = _clasificarCategoria(raw);
    final nombreLimpio = _limpiarNombre(rawName, brand);
    final presentacionData = _extraerPresentacionYContenido(
      rawQuantity,
      raw,
      categoria,
      nombreLimpio,
    );

    return DatosEscaneoProducto(
      codigo: codigo,
      nombre: nombreLimpio.isEmpty ? null : nombreLimpio,
      marca: brand.isEmpty ? null : brand,
      categoria: categoria,
      presentacion: presentacionData.presentacion,
      contenidoEnvase: presentacionData.contenido,
      unidad: presentacionData.unidad,
      imagenUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
    );
  }

  String _limpiarNombre(String rawName, String rawBrand) {
    String cleanName = rawName.trim();
    final cleanBrand = rawBrand.trim();

    String simplificar(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final nameSimple = simplificar(cleanName);
    final brandSimple = simplificar(cleanBrand);

    // Si el nombre no incluye las palabras clave de la marca, agregamos la marca
    if (brandSimple.isNotEmpty && cleanName.isNotEmpty) {
      final palabrasMarca = brandSimple.split(' ').where((w) => w.length > 1);
      final contieneMarca =
          palabrasMarca.isNotEmpty &&
          palabrasMarca.every((palabra) => nameSimple.contains(palabra));

      if (!contieneMarca) {
        cleanName = '$cleanName $cleanBrand';
      }
    } else if (cleanName.isEmpty && cleanBrand.isNotEmpty) {
      cleanName = cleanBrand;
    }

    // Deduplicar tokens considerando palabras compuestas/separadas por guiones
    final tokens = cleanName.split(RegExp(r'\s+'));
    final tokensLimpios = <String>[];
    final palabrasVistas = <String>{};

    for (final token in tokens) {
      final subpalabras = simplificar(token)
          .split(' ')
          .where((s) => s.isNotEmpty)
          .toList();
      if (subpalabras.isEmpty) continue;

      if (palabrasVistas.isNotEmpty &&
          subpalabras.every((sp) => palabrasVistas.contains(sp))) {
        continue;
      }

      for (final sp in subpalabras) {
        palabrasVistas.add(sp);
      }
      tokensLimpios.add(token);
    }

    cleanName = tokensLimpios.join(' ');

    // Formatear en Title Case respetando conectores comunes y unidades
    final regexUnidad = RegExp(
      r'^(\d+(?:\.\d+)?)(l|lt|litros?|ml|kg|kilos?|g|gr|gramos?)$',
      caseSensitive: false,
    );

    cleanName = cleanName.split(' ').map((p) {
      if (p.isEmpty) return p;
      final lower = p.toLowerCase();
      if (lower == 'de' ||
          lower == 'con' ||
          lower == 'en' ||
          lower == 'y' ||
          lower == 'el' ||
          lower == 'la' ||
          lower == 'al') {
        return lower;
      }

      final matchUnidad = regexUnidad.firstMatch(p);
      if (matchUnidad != null) {
        final numStr = matchUnidad.group(1)!;
        final unitStr = matchUnidad.group(2)!.toLowerCase();
        if (unitStr.startsWith('l') && !unitStr.startsWith('lim')) {
          return '$numStr L';
        } else if (unitStr.startsWith('ml')) {
          return '$numStr ml';
        } else if (unitStr.startsWith('kg') || unitStr.startsWith('kilo')) {
          return '$numStr kg';
        } else {
          return '$numStr g';
        }
      }

      if (p.contains('-')) {
        return p
            .split('-')
            .map((part) => part.isNotEmpty
                ? '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}'
                : '')
            .join('-');
      }
      return '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}';
    }).join(' ');

    return cleanName.trim();
  }

  String _clasificarCategoria(Map<String, dynamic> raw) {
    final categoriesStr =
        '${raw['categories'] ?? ''} ${raw['categories_tags'] ?? ''}'
            .toLowerCase();

    if (categoriesStr.contains('dairy') ||
        categoriesStr.contains('leche') ||
        categoriesStr.contains('queso') ||
        categoriesStr.contains('yogur') ||
        categoriesStr.contains('crema') ||
        categoriesStr.contains('mantequilla') ||
        categoriesStr.contains('lact') ||
        categoriesStr.contains('milks') ||
        categoriesStr.contains('cheeses')) {
      return 'Lácteos';
    }

    if (categoriesStr.contains('cereal') ||
        categoriesStr.contains('arroz') ||
        categoriesStr.contains('frijol') ||
        categoriesStr.contains('pasta') ||
        categoriesStr.contains('grano') ||
        categoriesStr.contains('avena') ||
        categoriesStr.contains('lent') ||
        categoriesStr.contains('legumbre')) {
      return 'Granos';
    }

    if (categoriesStr.contains('canned') ||
        categoriesStr.contains('enlatad') ||
        categoriesStr.contains('lata') ||
        categoriesStr.contains('conserva') ||
        categoriesStr.contains('atun') ||
        categoriesStr.contains('atún') ||
        categoriesStr.contains('sardina')) {
      return 'Enlatados';
    }

    if (categoriesStr.contains('beverage') ||
        categoriesStr.contains('drink') ||
        categoriesStr.contains('refresco') ||
        categoriesStr.contains('jugo') ||
        categoriesStr.contains('agua') ||
        categoriesStr.contains('bebida') ||
        categoriesStr.contains('soda')) {
      return 'Bebidas';
    }

    if (categoriesStr.contains('meat') ||
        categoriesStr.contains('carne') ||
        categoriesStr.contains('pollo') ||
        categoriesStr.contains('pescado') ||
        categoriesStr.contains('embutido') ||
        categoriesStr.contains('jamon') ||
        categoriesStr.contains('salchicha')) {
      return 'Carnes y Pescados';
    }

    if (categoriesStr.contains('fruit') ||
        categoriesStr.contains('vegetable') ||
        categoriesStr.contains('fruta') ||
        categoriesStr.contains('verdura')) {
      return 'Frutas y Verduras';
    }

    if (categoriesStr.contains('clean') ||
        categoriesStr.contains('hygiene') ||
        categoriesStr.contains('limpieza') ||
        categoriesStr.contains('jabon') ||
        categoriesStr.contains('detergente')) {
      return 'Limpieza e Higiene';
    }

    return 'Otros';
  }

  _PresentacionInfo _extraerPresentacionYContenido(
    String rawQuantity,
    Map<String, dynamic> raw,
    String categoria,
    String nombre,
  ) {
    final q = rawQuantity.toLowerCase();
    final nameLower = nombre.toLowerCase();
    final packagingStr =
        '${raw['packaging'] ?? ''} ${raw['packaging_tags'] ?? ''}'
            .toLowerCase();

    final esBebida = categoria == 'Bebidas' ||
        nameLower.contains('refresco') ||
        nameLower.contains('coca') ||
        nameLower.contains('pepsi') ||
        nameLower.contains('agua') ||
        nameLower.contains('jugo') ||
        nameLower.contains('cerveza') ||
        nameLower.contains('aceite');

    // Detección de unidad y cantidad numérica
    final regex = RegExp(r'([\d.,]+)\s*(ml|l|lt|litros?|kg|kilos?|g|gr|gramos?)');
    final match = regex.firstMatch(q.isNotEmpty ? q : nameLower);

    if (match != null) {
      final numStr = match.group(1)!.replaceAll(',', '.');
      final unitStr = match.group(2)!;
      final val = double.tryParse(numStr);

      if (val != null && val > 0) {
        String unidad;
        PresentacionCompra presentacion;

        if (unitStr.startsWith('ml')) {
          unidad = 'ml';
          if (packagingStr.contains('lata') || packagingStr.contains('can')) {
            presentacion = PresentacionCompra.lata;
          } else if (packagingStr.contains('bolsa') || packagingStr.contains('pouch')) {
            presentacion = PresentacionCompra.bolsa;
          } else if (packagingStr.contains('tetra') || packagingStr.contains('brick') || packagingStr.contains('brik')) {
            presentacion = PresentacionCompra.carton;
          } else {
            presentacion = PresentacionCompra.botella;
          }
        } else if (unitStr.startsWith('l')) {
          unidad = 'L';
          if (packagingStr.contains('bolsa')) {
            presentacion = PresentacionCompra.bolsa;
          } else if (!esBebida &&
              (packagingStr.contains('tetra') ||
                  packagingStr.contains('brick') ||
                  packagingStr.contains('brik') ||
                  categoria == 'Lácteos') &&
              !packagingStr.contains('botella') &&
              !packagingStr.contains('pet')) {
            presentacion = PresentacionCompra.carton;
          } else {
            // Refrescos, bebidas, aguas, aceites en litros son siempre botellas por defecto
            presentacion = PresentacionCompra.botella;
          }
        } else if (unitStr.startsWith('kg') || unitStr.startsWith('kilo')) {
          unidad = 'kg';
          if (packagingStr.contains('frasco')) {
            presentacion = PresentacionCompra.frasco;
          } else if (packagingStr.contains('caja')) {
            presentacion = PresentacionCompra.caja;
          } else {
            presentacion = PresentacionCompra.bolsa;
          }
        } else {
          unidad = 'g';
          if (categoria == 'Enlatados' || packagingStr.contains('lata')) {
            presentacion = PresentacionCompra.lata;
          } else if (packagingStr.contains('frasco')) {
            presentacion = PresentacionCompra.frasco;
          } else if (packagingStr.contains('caja')) {
            presentacion = PresentacionCompra.caja;
          } else {
            presentacion = PresentacionCompra.bolsa;
          }
        }

        return _PresentacionInfo(
          presentacion: presentacion,
          contenido: val,
          unidad: unidad,
        );
      }
    }

    // Si no pudimos deducir cantidad precisa con unidad:
    if (esBebida) {
      return const _PresentacionInfo(
        presentacion: PresentacionCompra.botella,
        contenido: 1.0,
        unidad: 'L',
      );
    }

    if (categoria == 'Lácteos') {
      return const _PresentacionInfo(
        presentacion: PresentacionCompra.carton,
        contenido: 1.0,
        unidad: 'L',
      );
    }

    return const _PresentacionInfo(
      presentacion: PresentacionCompra.pieza,
      contenido: 1.0,
      unidad: 'pza',
    );
  }
}

class _PresentacionInfo {
  final PresentacionCompra presentacion;
  final double contenido;
  final String unidad;

  const _PresentacionInfo({
    required this.presentacion,
    required this.contenido,
    required this.unidad,
  });
}
