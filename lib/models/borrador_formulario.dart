import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Modelo de borrador para preservar el estado del formulario de producto
/// si el sistema operativo Android destruye la actividad en segundo plano
/// al abrir la cámara del dispositivo.
class ProductFormDraft {
  final String name;
  final String category;
  final String zone;
  final String unit;
  final double minimum;
  final double quantity;
  final DateTime fechaCaducidad;
  final String? imagePath;
  final int? productId;
  final String? code;
  final String? packaging;
  final double? packageContent;
  final double? price;
  final int? ultimaTiendaId;

  const ProductFormDraft({
    required this.name,
    required this.category,
    this.zone = 'Nevera',
    required this.unit,
    required this.minimum,
    required this.quantity,
    required this.fechaCaducidad,
    this.imagePath,
    this.productId,
    this.code,
    this.packaging,
    this.packageContent,
    this.price,
    this.ultimaTiendaId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'zone': zone,
    'unit': unit,
    'minimum': minimum,
    'quantity': quantity,
    'fechaCaducidad': fechaCaducidad.toIso8601String(),
    'imagePath': imagePath,
    'productId': productId,
    'code': code,
    'packaging': packaging,
    'packageContent': packageContent,
    'price': price,
    'ultimaTiendaId': ultimaTiendaId,
  };

  factory ProductFormDraft.fromJson(Map<String, dynamic> map) => ProductFormDraft(
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? 'Lácteos',
    zone: map['zone'] as String? ?? 'Nevera',
    unit: map['unit'] as String? ?? 'pza',
    minimum: (map['minimum'] as num?)?.toDouble() ?? 2.0,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
    fechaCaducidad: map['fechaCaducidad'] != null
        ? (DateTime.tryParse(map['fechaCaducidad'] as String) ??
            DateTime.now().add(const Duration(days: 7)))
        : DateTime.now().add(const Duration(days: 7)),
    imagePath: map['imagePath'] as String?,
    productId: map['productId'] as int?,
    code: map['code'] as String?,
    packaging: map['packaging'] as String?,
    packageContent: (map['packageContent'] as num?)?.toDouble(),
    price: (map['price'] as num?)?.toDouble(),
    ultimaTiendaId: map['ultimaTiendaId'] as int?,
  );

  static Future<File?> _getFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory().timeout(
        const Duration(milliseconds: 300),
      );
      return File(p.join(appDir.path, 'product_form_draft.json'));
    } catch (_) {
      return null;
    }
  }

  static Future<void> guardar(ProductFormDraft draft) async {
    try {
      final file = await _getFile();
      if (file == null) return;
      await file.writeAsString(jsonEncode(draft.toJson()));
    } catch (_) {}
  }

  static Future<ProductFormDraft?> cargar() async {
    try {
      final file = await _getFile();
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final map = jsonDecode(content) as Map<String, dynamic>;
      return ProductFormDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> limpiar() async {
    try {
      final file = await _getFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
