import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';

/// Cada sección conserva su identidad dentro del encabezado común de Alacena.
enum AppSection {
  home('Inicio', Icons.kitchen_outlined),
  calendar('Calendario de alertas', Icons.calendar_month_outlined),
  stores('Tiendas', Icons.storefront_outlined),
  shoppingLists('Mi lista de compras', Icons.shopping_cart_outlined),
  productDetail('Detalle del producto', Icons.inventory_2_outlined),
  newProduct('Nuevo artículo', Icons.add_box_outlined),
  editProduct('Editar artículo', Icons.edit_note_rounded),
  newStore('Nueva tienda', Icons.add_business_outlined),
  editStore('Editar tienda', Icons.edit_location_alt_outlined),
  purchase('Registrar compra', Icons.receipt_long_outlined),
  purchaseHistory('Historial de compras', Icons.history_rounded),
  dayAlerts('Productos del día', Icons.event_note_outlined);

  const AppSection(this.title, this.icon);
  final String title;
  final IconData icon;
}

class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({super.key, required this.section, this.count});

  final AppSection section;
  final String? count;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 160;
      final logoSize = compact ? 32.0 : 38.0;
      return Row(
        children: [
          Semantics(
            image: true,
            label: 'Logo de ${section.title}',
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: PantryColors.green,
                borderRadius: BorderRadius.circular(compact ? 10 : 12),
              ),
              child: ExcludeSemantics(
                child: Icon(
                  section.icon,
                  size: compact ? 21 : 23,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ALACENA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 8 : 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: compact ? .9 : 1.6,
                    color: PantryColors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: section.title,
                  child: Text(
                    section.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13 : 16,
                      fontWeight: FontWeight.w600,
                      color: PantryColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: PantryColors.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count!,
                style: const TextStyle(fontSize: 9, color: PantryColors.green),
              ),
            ),
          ],
        ],
      );
    },
  );
}
