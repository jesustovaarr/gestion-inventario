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
  });

  final PantryProductPreview product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PantryColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: PantryColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductThumbnail(
                kind: product.thumbnail,
                imagePath: product.imagePath,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ProductStatusPill(status: product.status),
                        Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: PantryColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 7,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          product.note,
                          style: TextStyle(
                            fontSize: 10,
                            color: product.status == PantryPreviewStatus.healthy
                                ? PantryColors.muted
                                : product.status.color,
                          ),
                        ),
                        Text(
                          '·  ${product.quantity}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: PantryColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              IconButton(
                tooltip: 'Agregar ${product.name} al carrito',
                onPressed: onAddToCart ?? () {},
                style: IconButton.styleFrom(
                  backgroundColor: PantryColors.background,
                  foregroundColor: PantryColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                iconSize: 20,
                icon: const Icon(Icons.add_shopping_cart_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductStatusPill extends StatelessWidget {
  const ProductStatusPill({super.key, required this.status});

  final PantryPreviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 10, color: status.color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
