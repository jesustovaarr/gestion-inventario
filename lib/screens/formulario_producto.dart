import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../presentation/datos_alacena_demostracion.dart';
import '../widgets/miniatura_producto.dart';
import '../models/producto_model.dart';
import '../models/lote_model.dart';
import '../models/categoria_model.dart';
import '../database/daos/producto_dao.dart';
import '../database/daos/lote_dao.dart';
import '../database/daos/categoria_dao.dart';

// Formulario para dar de alta o editar productos
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final PantryProductPreview? product;
  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _productoDao = ProductoDao();
  final _loteDao = LoteDao();
  final _categoriaDao = CategoriaDao();

  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _minimumController;
  late TextEditingController _quantityController;

  String _name = '';
  String _category = 'Lácteos';
  String _unit = 'pza';
  String _zone = 'Nevera';
  String _time = '09:00 AM';
  double _minimum = 2.0;
  double _quantity = 1.0;
  bool _reminder = true;
  DateTime _fechaCaducidad = DateTime.now().add(const Duration(days: 7));
  bool _guardando = false;
  List<Categoria> _categoriasBD = [];

  String _formatearNumero(double n) {
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toString();
  }

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _category = widget.product?.category ?? 'Lácteos';
    _unit = widget.product != null
        ? (widget.product!.unit.toLowerCase() == 'lt' ? 'L' : widget.product!.unit)
        : 'pza';
    _minimum = widget.product?.minimumStock.toDouble() ?? 2.0;
    _quantity = 1.0;

    _nameController = TextEditingController(text: _name);
    _minimumController = TextEditingController(text: _formatearNumero(_minimum));
    _quantityController = TextEditingController(text: _formatearNumero(_quantity));
    _dateController = TextEditingController(
      text:
          '${_fechaCaducidad.day.toString().padLeft(2, '0')}/${_fechaCaducidad.month.toString().padLeft(2, '0')}/${_fechaCaducidad.year}',
    );
    _cargarCategorias();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _minimumController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _incrementarMinimo() {
    final parsed = double.tryParse(_minimumController.text) ?? _minimum;
    final nuevo = parsed + 1.0;
    setState(() {
      _minimum = nuevo;
      _minimumController.text = _formatearNumero(nuevo);
    });
  }

  void _decrementarMinimo() {
    final parsed = double.tryParse(_minimumController.text) ?? _minimum;
    if (parsed > 1.0) {
      final nuevo = parsed - 1.0;
      setState(() {
        _minimum = nuevo;
        _minimumController.text = _formatearNumero(nuevo);
      });
    } else if (parsed > 0.1) {
      final nuevo = (parsed - 0.5).clamp(0.0, double.infinity);
      setState(() {
        _minimum = nuevo;
        _minimumController.text = _formatearNumero(nuevo);
      });
    }
  }

  void _incrementarCantidad() {
    final parsed = double.tryParse(_quantityController.text) ?? _quantity;
    final nuevo = parsed + 1.0;
    setState(() {
      _quantity = nuevo;
      _quantityController.text = _formatearNumero(nuevo);
    });
  }

  void _decrementarCantidad() {
    final parsed = double.tryParse(_quantityController.text) ?? _quantity;
    if (parsed > 1.0) {
      final nuevo = parsed - 1.0;
      setState(() {
        _quantity = nuevo;
        _quantityController.text = _formatearNumero(nuevo);
      });
    } else if (parsed > 0.0) {
      final nuevo = (parsed - 0.5).clamp(0.0, double.infinity);
      setState(() {
        _quantity = nuevo;
        _quantityController.text = _formatearNumero(nuevo);
      });
    }
  }

  Future<void> _cargarCategorias() async {
    final cats = await _categoriaDao.obtenerTodas();
    if (mounted) {
      setState(() => _categoriasBD = cats);
    }
  }

  String _formatearFechaIso(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCaducidad,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _fechaCaducidad = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _guardar() async {
    final parsedMin = double.tryParse(_minimumController.text) ?? _minimum;
    final parsedQty = double.tryParse(_quantityController.text) ?? _quantity;

    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del producto es obligatorio'),
          backgroundColor: PantryColors.red,
        ),
      );
      return;
    }

    if (parsedMin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El stock mínimo debe ser mayor a 0'),
          backgroundColor: PantryColors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      int catId = 1;
      final encontrada = _categoriasBD.where(
        (c) => c.nombre.toLowerCase() == _category.toLowerCase(),
      );
      if (encontrada.isNotEmpty) {
        catId = encontrada.first.id!;
      } else {
        catId = await _categoriaDao.insertar(_category);
      }

      final unidadParaBD = _unit.toLowerCase() == 'l' ? 'lt' : _unit.toLowerCase();

      if (widget.isEditing) {
        final prodExistente = await _productoDao.obtenerPorId(widget.product!.id ?? 1);
        final actualizado = Producto(
          id: widget.product!.id,
          nombre: _name.trim(),
          unidadMedida: unidadParaBD,
          stockMinimo: parsedMin,
          categoriaId: catId,
          ultimaTiendaId: prodExistente?.ultimaTiendaId,
        );
        await _productoDao.actualizar(actualizado);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              backgroundColor: PantryColors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final nuevoProd = Producto(
          nombre: _name.trim(),
          unidadMedida: unidadParaBD,
          stockMinimo: parsedMin,
          categoriaId: catId,
        );
        final nuevoId = await _productoDao.insertar(nuevoProd);

        if (parsedQty > 0) {
          await _loteDao.insertarLote(
            Lote(
              productoId: nuevoId,
              cantidad: parsedQty,
              fechaCaducidad: _formatearFechaIso(_fechaCaducidad),
              alarmaActiva: _reminder ? 1 : 0,
            ),
          );
        }

        if (mounted) {
          String mensaje;
          if (parsedQty > 0 && parsedQty > parsedMin) {
            mensaje = 'La cantidad del lote supera el stock mínimo definido';
          } else {
            mensaje = 'Producto "$_name" guardado correctamente';
          }

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: PantryColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    title: AppSectionHeading(
                      section: widget.isEditing
                          ? AppSection.editProduct
                          : AppSection.newProduct,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        _ArticlePanel(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 26,
                                color: PantryColors.green,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Tienes el código de barras?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rellena los datos en 1 segundo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              FilledButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                  size: 13,
                                ),
                                label: const Text(
                                  'Escanear',
                                  style: TextStyle(fontSize: 10),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (widget.product == null)
                          const _PhotoPlaceholder()
                        else
                          Center(
                            child: ProductThumbnail(
                              kind: widget.product!.thumbnail,
                              imagePath: widget.product!.imagePath,
                              size: 130,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            _PhotoButton(
                              label: 'Cámara',
                              icon: Icons.camera_alt_outlined,
                            ),
                            _PhotoButton(
                              label: 'Galería',
                              icon: Icons.photo_library_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _ArticleLabel(
                          'Nombre del producto',
                          required: true,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          onChanged: (value) => setState(() => _name = value),
                          style: const TextStyle(fontSize: 12),
                          decoration: _articleInput().copyWith(
                            prefixIcon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: PantryColors.green,
                            ),
                            hintText: 'Ej. Leche deslactosada 1 L',
                            errorText: _name.trim().isEmpty
                                ? 'Este campo es obligatorio'
                                : null,
                            errorStyle: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _ArticleLabel('Categoría', required: true),
                        const SizedBox(height: 9),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in [
                                if (widget.product != null &&
                                    ![
                                      'Lácteos',
                                      'Granos',
                                      'Enlatados',
                                      'Otros',
                                    ].contains(widget.product!.category))
                                  (
                                    widget.product!.category,
                                    Icons.category_outlined,
                                  ),
                                ('Lácteos', Icons.kitchen_outlined),
                                ('Granos', Icons.grain_rounded),
                                ('Enlatados', Icons.inventory_2_outlined),
                                ('Otros', Icons.category_outlined),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(category.$1),
                                    avatar: Icon(
                                      category.$2,
                                      size: 15,
                                      color: _category == category.$1
                                          ? Colors.white
                                          : PantryColors.ink,
                                    ),
                                    selected: _category == category.$1,
                                    showCheckmark: false,
                                    selectedColor: PantryColors.green,
                                    backgroundColor: PantryColors.greenLight,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      color: _category == category.$1
                                          ? Colors.white
                                          : PantryColors.ink,
                                    ),
                                    side: BorderSide.none,
                                    onSelected: (_) =>
                                        setState(() => _category = category.$1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final units = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ArticleLabel(
                                  'Unidad de medida',
                                  required: true,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: PantryColors.greenLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      for (final unit in [
                                        'pza',
                                        'kg',
                                        'L',
                                        'g',
                                        'ml',
                                      ])
                                        Expanded(
                                          child: InkWell(
                                            onTap: () =>
                                                setState(() => _unit = unit),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 11,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _unit == unit
                                                    ? PantryColors.green
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: Text(
                                                unit,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _unit == unit
                                                      ? Colors.white
                                                      : PantryColors.ink,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Presentación básica',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PantryColors.muted,
                                  ),
                                ),
                              ],
                            );
                            final minimum = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ArticleLabel(
                                  'Stock mínimo',
                                  required: true,
                                ),
                                const SizedBox(height: 10),
                                _QuantityControl(
                                  controller: _minimumController,
                                  onDecrease: _decrementarMinimo,
                                  onIncrease: _incrementarMinimo,
                                  onChanged: (val) => setState(() => _minimum = val),
                                  label: 'stock mínimo',
                                ),
                                const SizedBox(height: 6),
                                if (_minimum <= 0)
                                  const Text(
                                    'Ingresa un valor mayor a 0',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.red,
                                    ),
                                  ),
                              ],
                            );
                            if (constraints.maxWidth < 350) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  units,
                                  const SizedBox(height: 18),
                                  minimum,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: units),
                                const SizedBox(width: 16),
                                Expanded(child: minimum),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        if (!widget.isEditing)
                          _ArticlePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: PantryColors.green,
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                'Primer lote',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              _ArticleTag('Entrada inicial'),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Registra la existencia actual y su fecha de vencimiento.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.4,
                                              color: PantryColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const _ArticleLabel(
                                  'Cantidad inicial',
                                  required: true,
                                ),
                                const SizedBox(height: 9),
                                _QuantityControl(
                                  controller: _quantityController,
                                  unit: _unit,
                                  onDecrease: _decrementarCantidad,
                                  onIncrease: _incrementarCantidad,
                                  onChanged: (val) => setState(() => _quantity = val),
                                  label: 'cantidad inicial',
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Existencias listas para almacenar',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PantryColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _ArticleLabel(
                                  'Fecha de caducidad',
                                  required: true,
                                ),
                                const SizedBox(height: 9),
                                TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap: _seleccionarFecha,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _articleInput().copyWith(
                                    hintText: 'dd/mm/aaaa',
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: PantryColors.green,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.event_outlined,
                                        size: 18,
                                        color: PantryColors.muted,
                                      ),
                                      onPressed: _seleccionarFecha,
                                    ),
                                    helperText: 'Fecha de caducidad para el lote inicial (FEFO)',
                                    helperStyle: const TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundColor:
                                                PantryColors.greenLight,
                                            child: Icon(
                                              Icons
                                                  .notifications_active_outlined,
                                              size: 17,
                                              color: PantryColors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Recordarme el día que caduca',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Recibir notificación en tu dispositivo',
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
                                            value: _reminder,
                                            onChanged: (value) => setState(
                                              () => _reminder = value,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: PantryColors.green,
                                          ),
                                          const SizedBox(width: 5),
                                          const Expanded(
                                            child: Text(
                                              'Hora del aviso:',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: PantryColors.muted,
                                              ),
                                            ),
                                          ),
                                          DropdownButton<String>(
                                            value: _time,
                                            underline: const SizedBox.shrink(),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PantryColors.green,
                                            ),
                                            items:
                                                const [
                                                      '08:00 AM',
                                                      '09:00 AM',
                                                      '06:00 PM',
                                                    ]
                                                    .map(
                                                      (time) =>
                                                          DropdownMenuItem(
                                                            value: time,
                                                            child: Text(time),
                                                          ),
                                                    )
                                                    .toList(),
                                            onChanged: _reminder
                                                ? (value) => setState(
                                                    () => _time = value!,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.isEditing)
                          const _ArticlePanel(
                            child: Text(
                              'Las existencias y las fechas se administran desde los lotes del producto.',
                              style: TextStyle(
                                fontSize: 12,
                                color: PantryColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Icon(
                              Icons.kitchen_outlined,
                              size: 15,
                              color: PantryColors.muted,
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: _ArticleLabel('Zona de almacenamiento'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final zone in [
                              ('Nevera', Icons.kitchen_outlined),
                              ('Alacena', Icons.inventory_2_outlined),
                              ('Congelador', Icons.ac_unit_rounded),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Material(
                                    color: _zone == zone.$1
                                        ? PantryColors.greenLight
                                        : const Color(0xFFEAF3EB),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _zone = zone.$1),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                          horizontal: 3,
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              zone.$2,
                                              size: 20,
                                              color: _zone == zone.$1
                                                  ? PantryColors.green
                                                  : PantryColors.muted,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              zone.$1,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _zone == zone.$1
                                                    ? PantryColors.green
                                                    : PantryColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _guardando ? null : _guardar,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.isEditing
                                      ? 'Guardar cambios'
                                      : 'Guardar artículo',
                                  style: const TextStyle(fontSize: 13),
                                ),
                        ),
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
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

InputDecoration _articleInput() => InputDecoration(
  filled: true,
  fillColor: const Color(0xFFEAF4EC),
  hintStyle: const TextStyle(fontSize: 11, color: PantryColors.muted),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide.none,
  ),
);

class _ArticlePanel extends StatelessWidget {
  const _ArticlePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF4EC),
      borderRadius: BorderRadius.circular(15),
    ),
    child: child,
  );
}

class _ArticleLabel extends StatelessWidget {
  const _ArticleLabel(this.text, {this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: text),
        if (required)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: PantryColors.red),
          ),
      ],
    ),
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class _ArticleTag extends StatelessWidget {
  const _ArticleTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: PantryColors.greenLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 9, color: PantryColors.green),
    ),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFE1ECE4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: PantryColors.background,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 26,
                    color: PantryColors.green,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Foto opcional',
                  style: TextStyle(fontSize: 10, color: PantryColors.muted),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              onPressed: () {},
              tooltip: 'Editar foto',
              icon: const Icon(Icons.edit_outlined, size: 16),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () {},
    icon: Icon(icon, size: 14),
    label: Text(label, style: const TextStyle(fontSize: 11)),
    style: FilledButton.styleFrom(
      backgroundColor: PantryColors.greenLight,
      foregroundColor: PantryColors.green,
      minimumSize: const Size(0, 34),
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.controller,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
    required this.label,
    this.unit,
  });

  final TextEditingController controller;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<double> onChanged;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: PantryColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: PantryColors.border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        IconButton(
          onPressed: onDecrease,
          tooltip: 'Disminuir $label',
          icon: const Icon(
            Icons.remove_rounded,
            size: 18,
            color: PantryColors.muted,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PantryColors.ink,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (text) {
                    final valor = double.tryParse(text) ?? 0.0;
                    onChanged(valor);
                  },
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 6),
                  child: Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PantryColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: onIncrease,
          tooltip: 'Aumentar $label',
          icon: const Icon(
            Icons.add_rounded,
            size: 18,
            color: PantryColors.green,
          ),
        ),
      ],
    ),
  );
}
