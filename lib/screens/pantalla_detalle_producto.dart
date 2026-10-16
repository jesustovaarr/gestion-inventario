import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import '../components/tema_alacena.dart';
import '../presentation/datos_alacena_demostracion.dart';
import '../widgets/miniatura_producto.dart';
import 'pantalla_registrar_compra.dart';
import 'formulario_producto.dart';

/// Detalle visual con datos fijos. Los controles no alteran existencias.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final PantryProductPreview product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 68,
                    leadingWidth: 40,
                    pinned: true,
                    titleSpacing: 0,
                    title: const AppSectionHeading(
                      section: AppSection.productDetail,
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        tooltip: 'Compartir',
                        icon: const Icon(Icons.share_outlined, size: 20),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProductFormScreen(product: product),
                          ),
                        ),
                        tooltip: 'Editar artículo',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(child: _ProductCover(product: product)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.kitchen_outlined,
                              size: 14,
                              color: PantryColors.muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Refrigerador · ${product.category}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ),
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: PantryColors.greenLight,
                              child: Icon(
                                Icons.water_drop_outlined,
                                size: 19,
                                color: PantryColors.green,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        color: PantryColors.green,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '5',
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' piezas',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '  (stock total)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: PantryColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const _Tag(
                                    'En orden',
                                    color: PantryColors.green,
                                    background: PantryColors.greenLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: .7,
                                  minHeight: 7,
                                  backgroundColor: PantryColors.greenLight,
                                  color: PantryColors.green,
                                ),
                              ),
                              const SizedBox(height: 9),
                              const Wrap(
                                spacing: 18,
                                runSpacing: 5,
                                children: [
                                  Text(
                                    '● Mínimo sugerido: 2 pzas',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                  Text(
                                    'Capacidad ideal: 7 pzas',
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
                        const SizedBox(height: 12),
                        const _Panel(
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: PantryColors.green,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Última compra · Walmart',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      '12 de octubre · \$28.50 MXN / pza',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: PantryColors.muted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Consumo exprés',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Resta del lote #1',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    tooltip: 'Disminuir cantidad',
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  const Text(
                                    '1',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    tooltip: 'Aumentar cantidad',
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Consumir unidades',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ActionButton(
                              label: 'Anotar compra',
                              icon: Icons.shopping_bag_outlined,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      RegisterPurchaseScreen(product: product),
                                ),
                              ),
                            ),
                            _ActionButton(
                              label: 'Agregar lote',
                              icon: Icons.add_box_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _Panel(
                          color: Color(0xFFE0ECE8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: Color(0xFF38656A),
                                child: Icon(
                                  Icons.insights_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ritmo de consumo inteligente',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Tu hogar consume un promedio de 1.2 piezas por semana. Al ritmo actual, tus existencias durarán aproximadamente 29 días.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.5,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        DefaultTabController(
                          length: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: PantryColors.greenLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              onTap: (value) => setState(() => _tab = value),
                              labelColor: PantryColors.green,
                              unselectedLabelColor: PantryColors.muted,
                              labelStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              indicatorPadding: const EdgeInsets.all(4),
                              tabs: const [
                                Tab(text: 'Lotes activos (3)'),
                                Tab(text: 'Historial (4)'),
                                Tab(text: 'Tiendas y precios'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverList.list(
                      children: _tab == 0
                          ? const [
                              _LotCard(
                                code: '#L-1094',
                                date: '6 de octubre de 2024',
                                quantity: '1 pza',
                                location: 'Puerta del refrigerador',
                                urgent: true,
                              ),
                              _LotCard(
                                code: '#L-1102',
                                date: '28 de octubre de 2024',
                                quantity: '2 pzas',
                                location: 'Estante medio',
                              ),
                              _LotCard(
                                code: '#L-1145',
                                date: '15 de noviembre de 2024',
                                quantity: '2 pzas',
                                location: 'Fondo del refrigerador',
                              ),
                            ]
                          : _tab == 1
                          ? const [
                              _HistoryRow(
                                title: 'Compra en Walmart',
                                subtitle: '12 oct 2024 · 2 piezas',
                                trailing: '\$57.00',
                              ),
                              _HistoryRow(
                                title: 'Compra en Soriana',
                                subtitle: '6 oct 2024 · 3 piezas',
                                trailing: '\$87.00',
                              ),
                            ]
                          : const [
                              _HistoryRow(
                                title: 'Walmart',
                                subtitle: 'Última compra: 12 oct 2024',
                                trailing: '\$28.50 / pza',
                              ),
                              _HistoryRow(
                                title: 'Soriana',
                                subtitle: 'Última compra: 6 oct 2024',
                                trailing: '\$29.00 / pza',
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

class _ProductCover extends StatelessWidget {
  const _ProductCover({required this.product});
  final PantryProductPreview product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB6C1AF), Color(0xFFEAE3CC)],
              ),
            ),
          ),
          Center(
            child: ProductThumbnail(
              kind: product.thumbnail,
              imagePath: product.imagePath,
              size: 220,
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 12,
            child: _Tag(
              'Lote próximo a vencer en 2 días',
              color: PantryColors.red,
              background: PantryColors.redLight,
            ),
          ),
          const Positioned(
            right: 16,
            top: 12,
            child: _Tag(
              'FEFO activo',
              color: PantryColors.green,
              background: PantryColors.background,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color = const Color(0xFFE9F3EA)});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(15),
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color, required this.background});
  final String text;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: onPressed ?? () {},
    icon: Icon(icon, size: 16),
    label: Text(label, style: const TextStyle(fontSize: 11)),
    style: FilledButton.styleFrom(
      backgroundColor: PantryColors.greenLight,
      foregroundColor: PantryColors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _LotCard extends StatelessWidget {
  const _LotCard({
    required this.code,
    required this.date,
    required this.quantity,
    required this.location,
    this.urgent = false,
  });
  final String code;
  final String date;
  final String quantity;
  final String location;
  final bool urgent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _Panel(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _Tag(
                      urgent ? 'Vence en 2 días' : 'En orden',
                      color: urgent ? PantryColors.red : PantryColors.green,
                      background: urgent
                          ? PantryColors.redLight
                          : PantryColors.greenLight,
                    ),
                    if (urgent)
                      const _Tag(
                        'Consumir 1.º',
                        color: PantryColors.green,
                        background: PantryColors.greenLight,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    quantity,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: urgent ? PantryColors.red : PantryColors.ink,
                    ),
                  ),
                  const Text(
                    'Disponibles',
                    style: TextStyle(fontSize: 9, color: PantryColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Lote $code',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'Caduca el $date',
            style: const TextStyle(fontSize: 11, color: PantryColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.kitchen_outlined,
                size: 13,
                color: PantryColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontSize: 10,
                    color: PantryColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (urgent)
                FilledButton(
                  onPressed: () {},
                  child: const Text(
                    'Consumir ahora',
                    style: TextStyle(fontSize: 10),
                  ),
                )
              else
                TextButton(
                  onPressed: () {},
                  child: const Text('Detalles', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final String title;
  final String subtitle;
  final String trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _Panel(
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
        trailing: Text(
          trailing,
          style: const TextStyle(fontSize: 12, color: PantryColors.green),
        ),
      ),
    ),
  );
}
