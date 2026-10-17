import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../widgets/miniatura_producto.dart';
import '../models/lote_model.dart';
import '../models/historial_compra_model.dart';
import '../models/tienda_model.dart';
import '../database/daos/lote_dao.dart';
import '../database/daos/compra_dao.dart';
import '../database/daos/producto_dao.dart';
import 'pantalla_registrar_compra.dart';
import 'formulario_producto.dart';

/// Detalle del producto
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final PantryProductPreview product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final LoteDao _loteDao = LoteDao();
  final CompraDao _compraDao = CompraDao();
  final ProductoDao _productoDao = ProductoDao();

  int _tab = 0;
  int _consumoCantidad = 1;
  bool _consumiendo = false;

  double _stockActual = 5.0;
  List<Lote> _lotesBD = [];
  List<HistorialCompra> _historialBD = [];
  List<Tienda> _tiendasBD = [];

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    final pId = widget.product.id ?? 1;
    final lotes = await _loteDao.obtenerLotesActivosPorProducto(pId);
    final historial = await _compraDao.obtenerHistorialPorProducto(pId);
    final tiendas = await _compraDao.obtenerTiendasPorProducto(pId);
    final productoBD = await _productoDao.obtenerPorId(pId);

    if (mounted) {
      setState(() {
        _lotesBD = lotes;
        _historialBD = historial;
        _tiendasBD = tiendas;
        if (productoBD != null) {
          _stockActual = productoBD.stockActual;
        } else if (lotes.isNotEmpty) {
          _stockActual = lotes.fold(0.0, (sum, l) => sum + l.cantidad);
        } else {
          _stockActual = double.tryParse(widget.product.quantity.split(' ').first) ?? 5.0;
        }
      });
    }
  }

  Future<void> _consumirFEFO() async {
    if (_consumoCantidad <= 0) return;
    setState(() => _consumiendo = true);

    try {
      final pId = widget.product.id ?? 1;
      final exito = await _loteDao.descontarStockFEFO(pId, _consumoCantidad.toDouble());

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se consumieron $_consumoCantidad ${widget.product.unit} según criterio FEFO (del lote más próximo a vencer)',
              ),
              backgroundColor: PantryColors.green,
            ),
          );
          _cargarDetalles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock insuficiente para consumir la cantidad solicitada'),
              backgroundColor: PantryColors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _consumiendo = false);
    }
  }

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
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          onPressed: () async {
                            final modificado =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (_) =>
                                    ProductFormScreen(product: product),
                              ),
                            );
                            if (modificado == true) _cargarDetalles();
                          },
                          tooltip: 'Editar artículo',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                        ),
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
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: PantryColors.green,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _stockActual.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' ${product.unit}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '  (stock total)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: PantryColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _Tag(
                                    _stockActual <= 0
                                        ? 'Agotado'
                                        : (_stockActual <= product.minimumStock
                                            ? 'Por agotarse'
                                            : 'En orden'),
                                    color: _stockActual <= 0
                                        ? PantryColors.red
                                        : (_stockActual <= product.minimumStock
                                            ? PantryColors.amber
                                            : PantryColors.green),
                                    background: _stockActual <= 0
                                        ? PantryColors.redLight
                                        : (_stockActual <= product.minimumStock
                                            ? PantryColors.amberLight
                                            : PantryColors.greenLight),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (_stockActual / (product.minimumStock * 3.5)).clamp(0.0, 1.0),
                                  minHeight: 7,
                                  backgroundColor: PantryColors.greenLight,
                                  color: PantryColors.green,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 18,
                                runSpacing: 5,
                                children: [
                                  Text(
                                    '● Mínimo sugerido: ${product.minimumStock} ${product.unit}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                  Text(
                                    'Capacidad ideal: ${(product.minimumStock * 3.5).toInt()} ${product.unit}',
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
                        const SizedBox(height: 12),
                        _Panel(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                color: PantryColors.green,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _tiendasBD.isNotEmpty
                                          ? 'Última compra · ${_tiendasBD.first.nombre}'
                                          : 'Trazabilidad de compra',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _historialBD.isNotEmpty
                                          ? '${_historialBD.first.fechaCompra} · \$${_historialBD.first.precioUnitario.toStringAsFixed(2)} MXN / ${product.unit}'
                                          : 'Registra tus compras para guardar precios y tiendas históricas.',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
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
                                      'Consumo Express (FEFO)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Descuenta del lote que vence primero',
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
                                    onPressed: () {
                                      if (_consumoCantidad > 1) {
                                        setState(() => _consumoCantidad--);
                                      }
                                    },
                                    tooltip: 'Disminuir cantidad',
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  Text(
                                    '$_consumoCantidad',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _consumoCantidad++),
                                    tooltip: 'Aumentar cantidad',
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _consumiendo ? null : _consumirFEFO,
                                      child: _consumiendo
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Consumir $_consumoCantidad ${product.unit}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 11),
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
                              onPressed: () async {
                                final res = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => RegisterPurchaseScreen(
                                      product: product,
                                      productoId: product.id,
                                    ),
                                  ),
                                );
                                if (res == true) _cargarDetalles();
                              },
                            ),
                          ],
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
                              tabs: [
                                Tab(text: 'Lotes activos (${_lotesBD.isNotEmpty ? _lotesBD.length : 3})'),
                                Tab(text: 'Historial (${_historialBD.isNotEmpty ? _historialBD.length : 2})'),
                                const Tab(text: 'Tiendas y precios'),
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
                          ? (_lotesBD.isNotEmpty
                              ? _lotesBD.map((lote) {
                                  return _LotCard(
                                    code: '#L-${lote.id}',
                                    date: lote.fechaCaducidad,
                                    quantity: '${lote.cantidad.toInt()} ${product.unit}',
                                    location: lote.estaCaducado
                                        ? 'Caducado'
                                        : (lote.porCaducar ? 'Por caducar' : 'En orden'),
                                    urgent: lote.estaCaducado || lote.porCaducar,
                                  );
                                }).toList()
                              : const [
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
                                ])
                          : _tab == 1
                          ? (_historialBD.isNotEmpty
                              ? _historialBD.map((h) {
                                  return _HistoryRow(
                                    title: 'Compra en ${h.tiendaNombre ?? 'Tienda'}',
                                    subtitle: '${h.fechaCompra} · ${h.cantidad.toInt()} ${product.unit}',
                                    trailing: '\$${h.totalGasto.toStringAsFixed(2)}',
                                  );
                                }).toList()
                              : const [
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
                                ])
                          : (_tiendasBD.isNotEmpty
                              ? _tiendasBD.map((t) {
                                  final compra = _historialBD
                                      .where((h) => h.tiendaId == t.id)
                                      .firstOrNull;
                                  final precioTexto = compra != null
                                      ? '\$${compra.precioUnitario.toStringAsFixed(2)} / ${product.unit}'
                                      : (t.tipoTiendaNombre ?? 'Tienda');
                                  final subtitulo = compra != null
                                      ? 'Última compra: ${compra.fechaCompra}'
                                      : (t.ubicacion ?? 'Tienda registrada');

                                  return _HistoryRow(
                                    title: t.nombre,
                                    subtitle: subtitulo,
                                    trailing: precioTexto,
                                  );
                                }).toList()
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
                                ]),
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
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: PantryColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PantryColors.border),
      ),
      child: Center(
        child: ProductThumbnail(
          kind: product.thumbnail,
          imagePath: product.imagePath,
          size: 110,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PantryColors.border),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
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
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: PantryColors.green),
        label: Text(label, style: const TextStyle(fontSize: 11, color: PantryColors.ink)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: PantryColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: urgent ? PantryColors.orange : PantryColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              urgent ? Icons.hourglass_bottom_rounded : Icons.inventory_2_outlined,
              size: 20,
              color: urgent ? PantryColors.orange : PantryColors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        quantity,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PantryColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vence: $date · $location',
                    style: TextStyle(
                      fontSize: 10,
                      color: urgent ? PantryColors.orange : PantryColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PantryColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: PantryColors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: PantryColors.muted),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PantryColors.green,
              ),
            ),
          ],
        ),
      );
}
