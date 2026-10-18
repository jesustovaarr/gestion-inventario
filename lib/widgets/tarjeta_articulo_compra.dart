import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_compra.dart';
import '../utils/importes.dart';
import '../utils/presentaciones.dart';
import 'miniatura_producto.dart';

class PurchaseArticleCard extends StatelessWidget {
  const PurchaseArticleCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRemove,
    this.onIncrease,
    this.onDecrease,
  });
  final PurchaseArticleDraft item;
  final VoidCallback? onTap, onRemove, onIncrease, onDecrease;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(
                  kind: item.product.thumbnail,
                  imagePath: item.product.imagePath,
                  size: 52,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.quantityLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PantryColors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.priceCents == null
                            ? 'Indicar precio'
                            : '\$${formatearImporte(item.priceCents!)} por ${item.packaging.esEnvase ? item.packaging.singular.toLowerCase() : unidadVisible(item.product.unit)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PantryColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Quitar ${item.product.name}',
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 14,
                  color: PantryColors.muted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.expiryDate == null
                        ? 'Indicar caducidad'
                        : 'Cad: ${_date(item.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.expiryDate == null
                          ? PantryColors.orange
                          : PantryColors.muted,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    item.priceCents == null
                        ? 'Pendiente'
                        : '\$${formatearImporte(item.subtotalCents)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onIncrease != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDecrease,
                    tooltip: 'Quitar una unidad de ${item.product.name}',
                    icon: const Icon(Icons.remove, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onIncrease,
                    tooltip: 'Sumar una unidad de ${item.product.name}',
                    icon: const Icon(Icons.add, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
