import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import '../components/tema_alacena.dart';
import '../presentation/datos_alacena_demostracion.dart';
import '../widgets/miniatura_producto.dart';
import 'pantalla_nuevo_articulo.dart';

/// Formulario visual; no inserta compras, lotes ni movimientos de inventario.
class RegisterPurchaseScreen extends StatefulWidget {
  const RegisterPurchaseScreen({super.key, this.product});
  final PantryProductPreview? product;

  @override
  State<RegisterPurchaseScreen> createState() => _RegisterPurchaseScreenState();
}

class _RegisterPurchaseScreenState extends State<RegisterPurchaseScreen> {
  bool _updatePrice = true;

  @override
  Widget build(BuildContext context) {
    final product =
        widget.product ?? pantryPreviewSections.first.products.first;
    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 68,
                    leadingWidth: 40,
                    pinned: true,
                    titleSpacing: 0,
                    title: const AppSectionHeading(
                      section: AppSection.purchase,
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        tooltip: 'Escanear código',
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        tooltip: 'Más opciones',
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        const _PurchasePanel(
                          color: PantryColors.greenLight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFC4E3CF),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: PantryColors.green,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reposición de inventario',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: PantryColors.green,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Al guardar, se creará un nuevo lote en tu despensa y se actualizará el historial de la tienda para calcular tus métricas de consumo.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: PantryColors.muted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PurchasePanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: _FieldLabel('Producto *'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const NewArticleScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      '+ Nuevo producto',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              _FieldSurface(
                                child: Row(
                                  children: [
                                    ProductThumbnail(
                                      kind: product.thumbnail,
                                      imagePath: product.imagePath,
                                      size: 48,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.category} · ID: #0421',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: PantryColors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.unfold_more_rounded,
                                      size: 18,
                                      color: PantryColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '¿Buscando otro artículo?',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.search_rounded,
                                      size: 13,
                                    ),
                                    label: const Text(
                                      'Buscar en catálogo',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PurchasePanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Tienda / Supermercado *'),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: 'Walmart Supercenter',
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.storefront_outlined,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PantryColors.ink,
                                ),
                                items:
                                    const [
                                          'Walmart Supercenter',
                                          'Soriana Híper',
                                          'Bodega Aurrerá',
                                        ]
                                        .map(
                                          (store) => DropdownMenuItem(
                                            value: store,
                                            child: Text(
                                              store,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (_) {},
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Sucursal Perisur · Compra frecuente',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final quantity = _PurchasePanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Cantidad *'),
                                  const SizedBox(height: 10),
                                  _FieldSurface(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _QuantityButton(
                                          icon: Icons.remove_rounded,
                                          tooltip: 'Disminuir cantidad',
                                        ),
                                        const Text(
                                          '2',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        _QuantityButton(
                                          icon: Icons.add_rounded,
                                          tooltip: 'Aumentar cantidad',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Unidad: envase de 1 L',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            final price = _PurchasePanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Precio unitario *'),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    initialValue: '28.50',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: _inputDecoration().copyWith(
                                      prefixText: '\$ ',
                                      suffixText: 'MXN',
                                      suffixStyle: const TextStyle(
                                        fontSize: 9,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Total: \$57.00 MXN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: PantryColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (constraints.maxWidth < 350) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  quantity,
                                  const SizedBox(height: 14),
                                  price,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: quantity),
                                const SizedBox(width: 12),
                                Expanded(child: price),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _PurchasePanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Fecha de compra *'),
                              const SizedBox(height: 10),
                              TextFormField(
                                readOnly: true,
                                initialValue: 'Hoy, 24 de octubre de 2024',
                                style: const TextStyle(fontSize: 12),
                                decoration:
                                    _inputDecoration(
                                      prefixIcon: Icons.calendar_today_outlined,
                                    ).copyWith(
                                      suffixIcon: const Icon(
                                        Icons.event_outlined,
                                        size: 18,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 18),
                              const _FieldLabel(
                                'Fecha de caducidad (lote a generar) *',
                              ),
                              const SizedBox(height: 10),
                              const _FieldSurface(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_bottom_rounded,
                                      color: PantryColors.green,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '15 de noviembre de 2024',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Consumo preferente sugerido',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: PantryColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.event_outlined,
                                      size: 18,
                                      color: PantryColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Wrap(
                                spacing: 6,
                                runSpacing: 5,
                                children: [
                                  _PurchaseBadge('Genera lote #L-1146 (FEFO)'),
                                  _PurchaseBadge('Caduca en 22 días'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PurchasePanel(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Actualizar precio de referencia',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Sincroniza \$28.50 MXN como costo habitual de este producto.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: PantryColors.muted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _updatePrice,
                                    onChanged: (value) =>
                                        setState(() => _updatePrice = value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const _FieldSurface(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.kitchen_outlined,
                                      size: 19,
                                      color: PantryColors.muted,
                                    ),
                                    SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ubicación asignada',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: PantryColors.muted,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Refrigerador principal',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: PantryColors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _PurchasePanel(
                          color: PantryColors.greenLight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Stock resultante en despensa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '5 L',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: PantryColors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                child: LinearProgressIndicator(
                                  value: .625,
                                  minHeight: 6,
                                  color: PantryColors.green,
                                  backgroundColor: Color(0xFFC8DFCD),
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 22,
                                runSpacing: 5,
                                children: [
                                  Text(
                                    '3 actuales + 2 nuevos',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                  Text(
                                    'Capacidad óptima: 8 L',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Guardar compra',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.document_scanner_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Escanear ticket en su lugar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar operación',
                            style: TextStyle(
                              fontSize: 11,
                              color: PantryColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({IconData? prefixIcon}) => InputDecoration(
  filled: true,
  fillColor: PantryColors.background,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
  prefixIcon: prefixIcon == null
      ? null
      : Icon(prefixIcon, size: 19, color: PantryColors.green),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
);

class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: PantryColors.border),
    ),
    child: child,
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class _FieldSurface extends StatelessWidget {
  const _FieldSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: PantryColors.background,
      borderRadius: BorderRadius.circular(11),
    ),
    child: child,
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.tooltip});
  final IconData icon;
  final String tooltip;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () {},
    tooltip: tooltip,
    constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
    padding: const EdgeInsets.all(4),
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 18, color: PantryColors.green),
  );
}

class _PurchaseBadge extends StatelessWidget {
  const _PurchaseBadge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: PantryColors.greenLight,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 9, color: PantryColors.green),
    ),
  );
}
