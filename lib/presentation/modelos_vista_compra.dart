import '../models/compra_model.dart';
import '../models/carrito_model.dart';
import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';
import 'modelos_vista_alacena.dart';

class PurchaseArticleDraft {
  factory PurchaseArticleDraft.fromProduct(PantryProductPreview product) {
    final packaging =
        product.packaging == PresentacionCompra.granel && product.unit == 'pza'
        ? PresentacionCompra.pieza
        : product.packaging;
    final price = product.price == null
        ? null
        : product.price! *
              100 *
              (packaging.esEnvase ? product.packageContent : 1);
    return PurchaseArticleDraft(
      product: product,
      packaging: packaging,
      packageContent: product.packageContent,
      priceCents:
          price != null && price.isFinite && price >= 0 && price <= 99999999
          ? price.round()
          : null,
    );
  }
  const PurchaseArticleDraft({
    required this.product,
    double quantity = 1,
    this.priceCents,
    this.expiryDate,
    this.packaging = PresentacionCompra.granel,
    this.packageCount = 1,
    this.packageContent = 1,
  }) : _bulkQuantity = quantity;
  final PantryProductPreview product;
  final double _bulkQuantity;
  final int? priceCents;
  final DateTime? expiryDate;
  final PresentacionCompra packaging;
  final int packageCount;
  final double packageContent;
  String get key => (product.id ?? product.name).toString();
  double get quantity => packaging.esEnvase
      ? normalizarCantidad(packageCount * packageContent)
      : _bulkQuantity;
  String get quantityLabel => packaging.esEnvase
      ? '$packageCount ${packaging.etiqueta(packageCount)} de ${formatearContenido(packageContent, product.unit)}'
      : '${formatearCantidad(quantity)} ${unidadVisible(product.unit)} a granel';
  int get subtotalCents => priceCents == null ? 0 : _model('').subtotalCentavos;
  PurchaseArticleDraft copyWith({
    PantryProductPreview? product,
    double? quantity,
    int? priceCents,
    DateTime? expiryDate,
    PresentacionCompra? packaging,
    int? packageCount,
    double? packageContent,
  }) => PurchaseArticleDraft(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    priceCents: priceCents ?? this.priceCents,
    expiryDate: expiryDate ?? this.expiryDate,
    packaging: packaging ?? this.packaging,
    packageCount: packageCount ?? this.packageCount,
    packageContent: packageContent ?? this.packageContent,
  );
  ArticuloCompra _model(String expiry) => ArticuloCompra(
    productoId: product.id!,
    cantidad: quantity,
    precioUnitarioCentavos: priceCents ?? 0,
    fechaCaducidad: expiry,
    presentacion: packaging,
    numeroEnvases: packageCount,
    contenidoEnvase: packaging.esEnvase ? packageContent : 1,
  );
  ArticuloCompra toModel() =>
      _model(expiryDate!.toIso8601String().substring(0, 10));
  CarritoItem toCartItem() => CarritoItem(
    productoId: product.id!,
    cantidadAComprar: quantity,
    presentacion: packaging,
    numeroEnvases: packageCount,
    contenidoEnvase: packaging.esEnvase ? packageContent : 1,
    precioCentavos: priceCents,
    fechaCaducidad: expiryDate?.toIso8601String().substring(0, 10),
  );
}
