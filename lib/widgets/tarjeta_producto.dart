import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_alacena.dart';
import 'miniatura_producto.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onInventoryAction,
    this.shoppingQuantity,
    this.onRemove,
    this.onDecrease,
    this.onIncrease,
  });

  final PantryProductPreview product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onInventoryAction;
  final String? shoppingQuantity;
  final VoidCallback? onRemove;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final shopping = shoppingQuantity != null;
      final wide = constraints.maxWidth >= 440;
      final fontSize = wide ? 14.0 : 11.0;
      final hasStock = product.hasStock;
      final empty = !shopping && !hasStock;
      final quantityColor = empty
          ? const Color(0xFFEDF0F1)
          : const Color(0xFFE7F0E9);
      final quantityText = shopping
          ? '$shoppingQuantity ${product.unit} agregadas'
          : product.stockLabel;
      final location = [
        if (product.storageZone?.isNotEmpty == true) product.storageZone!,
        product.category,
      ].join(' · ');

      return Material(
        color: PantryColors.surface,
        elevation: 1,
        shadowColor: PantryColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(wide ? 28 : 22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(wide ? 24 : 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductThumbnail(
                      kind: product.thumbnail,
                      imagePath: product.imagePath,
                      size: wide ? 94 : 64,
                    ),
                    SizedBox(width: wide ? 16 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: wide ? 20 : 14,
                                    height: 1.25,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: wide ? 165 : 108,
                                ),
                                child: _ExpiryPill(
                                  product: product,
                                  empty: empty,
                                  wide: wide,
                                ),
                              ),
                            ],
                          ),
                          if (product.packaging.esEnvase) ...[
                            const SizedBox(height: 4),
                            Text(
                              product.presentationLabel,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: PantryColors.green,
                              ),
                            ),
                          ],
                          SizedBox(height: wide ? 6 : 5),
                          Row(
                            children: [
                              Icon(
                                Icons.kitchen_outlined,
                                size: fontSize + 3,
                                color: const Color(0xFF42554A),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: const Color(0xFF526258),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: wide ? 13 : 10),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: fontSize + 2,
                                color: const Color(0xFF42554A),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  product.expiryDate == null
                                      ? 'Sin caducidad'
                                      : product.formattedExpiry,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: const Color(0xFF526258),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: wide ? 12 : 6,
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  size: 5,
                                  color: Color(0xFFC0CFC3),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  shopping
                                      ? product.price == null
                                            ? 'Sin precio'
                                            : '\$${product.price!.toStringAsFixed(2)} / ${product.unit}'
                                      : product.lotId == null || !hasStock
                                      ? 'Sin lote activo'
                                      : 'Lote: #${product.lotId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: const Color(0xFF68786D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!shopping && product.stockDetail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        product.stockDetail!,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: PantryColors.muted,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: wide ? 24 : 14),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: wide ? 14 : 10,
                            vertical: wide ? 8 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: quantityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                shopping || empty
                                    ? Icons.shopping_cart_outlined
                                    : Icons.pie_chart_outline_rounded,
                                size: wide ? 20 : 16,
                                color: empty
                                    ? const Color(0xFF7B8990)
                                    : const Color(0xFF607266),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  quantityText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF405347),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (shopping) ...[
                      _QuantityButton(
                        icon: Icons.remove_rounded,
                        onPressed: onDecrease,
                        tooltip: 'Disminuir ${product.name}',
                      ),
                      Text(
                        shoppingQuantity!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add_rounded,
                        onPressed: onIncrease,
                        tooltip: 'Aumentar ${product.name}',
                      ),
                      _QuantityButton(
                        icon: Icons.delete_outline_rounded,
                        onPressed: onRemove,
                        tooltip: 'Eliminar ${product.name} de la lista',
                      ),
                    ] else ...[
                      if (hasStock && product.lotId != null) ...[
                        SizedBox(width: wide ? 12 : 8),
                        TextButton(
                          onPressed: onInventoryAction,
                          style: TextButton.styleFrom(
                            minimumSize: Size(wide ? 104 : 76, 40),
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 20 : 12,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: product.isExpired
                                ? PantryColors.redLight
                                : const Color(0xFFE2ECE5),
                            foregroundColor: product.isExpired
                                ? PantryColors.red
                                : const Color(0xFF405347),
                            textStyle: TextStyle(
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            product.isExpired ? 'Desechar' : 'Consumir',
                          ),
                        ),
                      ],
                      SizedBox(width: wide ? 12 : 8),
                      IconButton.filled(
                        tooltip: 'Agregar ${product.name} al carrito',
                        onPressed: onAddToCart,
                        style: IconButton.styleFrom(
                          backgroundColor: PantryColors.green,
                          foregroundColor: Colors.white,
                          fixedSize: Size.square(wide ? 50 : 40),
                          minimumSize: Size.square(wide ? 50 : 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(
                          Icons.add_shopping_cart_outlined,
                          size: wide ? 25 : 21,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({
    required this.product,
    required this.empty,
    required this.wide,
  });
  final PantryProductPreview product;
  final bool empty;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final color = empty ? const Color(0xFF657780) : product.status.color;
    final label = empty
        ? 'Sin existencia'
        : product.isExpired
        ? 'Caducado'
        : product.status == PantryPreviewStatus.expiring
        ? product.expiryLabel
        : product.status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: empty ? const Color(0xFFEDF0F1) : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            empty ? Icons.inventory_2_outlined : product.status.icon,
            size: wide ? 14 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: wide ? 12 : 9,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 18),
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 32, height: 40),
  );
}

class ProductStatusPill extends StatelessWidget {
  const ProductStatusPill({super.key, required this.status});
  final PantryPreviewStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: status.background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 12, color: status.color),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
