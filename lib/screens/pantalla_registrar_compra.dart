import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../widgets/miniatura_producto.dart';
import '../models/tienda_model.dart';
import '../models/producto_model.dart';
import '../database/daos/tienda_dao.dart';
import '../database/daos/compra_dao.dart';
import '../database/daos/producto_dao.dart';

/// Formulario para registrar compras
class RegisterPurchaseScreen extends StatefulWidget {
  const RegisterPurchaseScreen({super.key, this.product, this.productoId});
  final PantryProductPreview? product;
  final int? productoId;

  @override
  State<RegisterPurchaseScreen> createState() => _RegisterPurchaseScreenState();
}

class _RegisterPurchaseScreenState extends State<RegisterPurchaseScreen> {
  final TiendaDao _tiendaDao = TiendaDao();
  final CompraDao _compraDao = CompraDao();
  final ProductoDao _productoDao = ProductoDao();

  late final TextEditingController _precioController;
  int _cantidad = 2;
  double _precioUnitario = 28.50;
  DateTime _fechaCompra = DateTime.now();
  DateTime _fechaCaducidad = DateTime.now().add(const Duration(days: 22));

  List<Tienda> _tiendas = [];
  Tienda? _tiendaSeleccionada;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _precioController = TextEditingController(text: _precioUnitario.toStringAsFixed(2));
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final tiendas = await _tiendaDao.obtenerTodas();
    if (mounted) {
      setState(() {
        _tiendas = tiendas;
        if (tiendas.isNotEmpty) {
          _tiendaSeleccionada = tiendas.first;
        }
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  String _formatearFechaIso(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _formatearFechaLegible(DateTime d) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }

  Future<void> _seleccionarFechaCompra() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCompra,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _fechaCompra = picked);
    }
  }

  Future<void> _seleccionarFechaCaducidad() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCaducidad,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _fechaCaducidad = picked);
    }
  }

  Future<void> _guardarCompra(PantryProductPreview product) async {
    if (_tiendaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una tienda para registrar la compra'),
          backgroundColor: PantryColors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final double precioParsed = double.tryParse(_precioController.text.trim()) ?? _precioUnitario;

      // Obtener o asegurar productoId 
      int pId = widget.productoId ?? product.id ?? 1;

      // Verificar si el producto existe, si no, crearlo con datos base
      final prodEnBD = await _productoDao.obtenerPorId(pId);
      if (prodEnBD == null) {
        pId = await _productoDao.insertar(
          Producto(
            nombre: product.name,
            unidadMedida: product.unit,
            stockMinimo: product.minimumStock.toDouble(),
            categoriaId: 1,
            ultimaTiendaId: _tiendaSeleccionada!.id,
          ),
        );
      }

      final fechaCompraIso = _formatearFechaIso(_fechaCompra);
      final fechaCaducidadIso = _formatearFechaIso(_fechaCaducidad);

      await _compraDao.registrarCompra(
        productoId: pId,
        tiendaId: _tiendaSeleccionada!.id!,
        cantidad: _cantidad.toDouble(),
        precioUnitario: precioParsed,
        fechaCompra: fechaCompraIso,
        fechaCaducidad: fechaCaducidadIso,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compra guardada: $_cantidad ${product.unit} en ${_tiendaSeleccionada!.nombre} (Lote generado con criterio FEFO)',
            ),
            backgroundColor: PantryColors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar compra: $e'),
            backgroundColor: PantryColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product ??
        const PantryProductPreview(
          name: 'Producto',
          category: 'General',
          status: PantryPreviewStatus.healthy,
          note: '',
          quantity: '1 pza',
          thumbnail: ProductThumbnailKind.placeholder,
        );

    final double totalCompra = _cantidad * _precioUnitario;

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
                              Icon(
                                Icons.verified_outlined,
                                size: 16,
                                color: PantryColors.green,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                      height: 1.45,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Registro con trazabilidad obligatoria.\n',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: PantryColors.green,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'Genera un lote activo con vencimiento FEFO y registra el precio histórico por tienda.',
                                      ),
                                    ],
                                  ),
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
                              const _FieldLabel('Artículo de la alacena *'),
                              const SizedBox(height: 10),
                              _FieldSurface(
                                child: Row(
                                  children: [
                                    ProductThumbnail(
                                      kind: product.thumbnail,
                                      imagePath: product.imagePath,
                                      size: 40,
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
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.category} · Unidad: ${product.unit}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: PantryColors.green,
                                            ),
                                          ),
                                        ],
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
                              const _FieldLabel('Tienda / Supermercado *'),
                              const SizedBox(height: 10),
                              if (_cargando)
                                const LinearProgressIndicator()
                              else if (_tiendas.isEmpty)
                                const Text(
                                  'No hay tiendas registradas. Ve a la sección Tiendas para agregar una.',
                                  style: TextStyle(fontSize: 11, color: PantryColors.red),
                                )
                              else
                                DropdownButtonFormField<Tienda>(
                                  initialValue: _tiendaSeleccionada,
                                  isExpanded: true,
                                  decoration: _inputDecoration(
                                    prefixIcon: Icons.storefront_outlined,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PantryColors.ink,
                                  ),
                                  items: _tiendas
                                      .map(
                                        (store) => DropdownMenuItem(
                                          value: store,
                                          child: Text(
                                            '${store.nombre} (${store.tipoTiendaNombre ?? 'Tienda'})',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _tiendaSeleccionada = val);
                                    }
                                  },
                                ),
                              const SizedBox(height: 5),
                              Text(
                                _tiendaSeleccionada?.ubicacion ?? 'Ubicación de compra',
                                style: const TextStyle(
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
                                          onPressed: () {
                                            if (_cantidad > 1) {
                                              setState(() => _cantidad--);
                                            }
                                          },
                                        ),
                                        Text(
                                          '$_cantidad',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        _QuantityButton(
                                          icon: Icons.add_rounded,
                                          tooltip: 'Aumentar cantidad',
                                          onPressed: () => setState(() => _cantidad++),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unidad: ${product.unit}',
                                    style: const TextStyle(
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
                                    controller: _precioController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val);
                                      if (parsed != null) {
                                        setState(() => _precioUnitario = parsed);
                                      }
                                    },
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
                                  Text(
                                    'Total: \$${totalCompra.toStringAsFixed(2)} MXN',
                                    style: const TextStyle(
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
                              InkWell(
                                onTap: _seleccionarFechaCompra,
                                child: IgnorePointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text: _formatearFechaLegible(_fechaCompra),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    decoration: _inputDecoration(
                                      prefixIcon: Icons.calendar_today_outlined,
                                    ).copyWith(
                                      suffixIcon: const Icon(
                                        Icons.event_outlined,
                                        size: 18,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const _FieldLabel('Fecha de caducidad (lote a generar) *'),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _seleccionarFechaCaducidad,
                                child: _FieldSurface(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.hourglass_bottom_rounded,
                                        color: PantryColors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatearFechaLegible(_fechaCaducidad),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            const Text(
                                              'Toca para cambiar la caducidad del lote',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: PantryColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.event_outlined,
                                        size: 18,
                                        color: PantryColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _guardando ? null : () => _guardarCompra(product),
                          icon: _guardando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            _guardando ? 'Guardando en SQLite…' : 'Guardar compra',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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

  InputDecoration _inputDecoration({IconData? prefixIcon}) => InputDecoration(
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 16, color: PantryColors.muted)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: PantryColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: PantryColors.border),
        ),
      );
}

class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PantryColors.border),
        ),
        child: child,
      );
}

class _FieldSurface extends StatelessWidget {
  const _FieldSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PantryColors.background,
          borderRadius: BorderRadius.circular(12),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: PantryColors.ink,
        ),
      );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: PantryColors.border),
          minimumSize: const Size(36, 36),
        ),
        icon: Icon(icon, size: 16, color: PantryColors.ink),
      );
}
