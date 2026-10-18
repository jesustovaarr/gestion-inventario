import '../models/borrador_formulario.dart';
import '../models/datos_escaneo_producto.dart';
import '../widgets/selector_foto_producto.dart';
import '../widgets/campo_codigo_barras.dart';

import '../widgets/campos_presentacion_producto.dart';
import '../widgets/editor_lotes_producto.dart';
import '../widgets/historial_movimientos_producto.dart';
import '../database/daos/tienda_dao.dart';
import '../models/tienda_model.dart';
import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';
import '../utils/importes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../models/producto_model.dart';
import '../models/lote_model.dart';
import '../models/categoria_model.dart';
import '../database/daos/producto_dao.dart';
import '../database/daos/lote_dao.dart';
import '../database/daos/categoria_dao.dart';

// Formulario para dar de alta o editar productos
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
    this.draft,
    this.initialImagePath,
    this.catalogOnly = false,
    this.onSaved,
  });
  final PantryProductPreview? product;
  final ProductFormDraft? draft;
  final String? initialImagePath;
  final bool catalogOnly;
  final ValueChanged<int>? onSaved;
  bool get isEditing => product != null || draft?.productId != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _productoDao = ProductoDao();
  final _loteDao = LoteDao();
  final _categoriaDao = CategoriaDao();

  late TextEditingController _nameController;
  late TextEditingController _precioController;
  late TextEditingController _dateController;
  late TextEditingController _minimumController;
  late TextEditingController _quantityController;
  late TextEditingController _codeController;
  late TextEditingController _contentController;
  PresentacionCompra _packaging = PresentacionCompra.pieza;
  bool _eligiendoFecha = false;

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
  bool _cargando = false;
  bool _lotesValidos = true;
  String? _imagen;
  String? _errorCarga;
  List<Lote> _lotesEdicion = [];
  int _versionLotes = 0;
  List<Tienda> _tiendas = [];
  int? _ultimaTiendaId;
  List<Categoria> _categoriasBD = [];
  bool _borradorActivo = false;

  String _formatearNumero(double n) => formatearCantidad(n);

  @override
  void initState() {
    super.initState();
    _name = widget.draft?.name ?? widget.product?.name ?? '';
    _imagen = widget.initialImagePath ?? widget.draft?.imagePath ?? widget.product?.imagePath;
    _cargando = widget.isEditing && widget.product?.id != null;
    _zone = widget.draft?.zone ?? widget.product?.storageZone ?? 'Nevera';
    _category = widget.draft?.category ?? widget.product?.category ?? 'Lácteos';
    _unit = widget.draft?.unit ??
        (widget.product != null
            ? (widget.product!.unit.toLowerCase() == 'lt'
                ? 'L'
                : widget.product!.unit)
            : 'pza');
    _minimum = widget.draft?.minimum ?? widget.product?.minimumStock.toDouble() ?? 2.0;
    _quantity = widget.draft?.quantity ?? 1.0;
    _fechaCaducidad = widget.draft?.fechaCaducidad ?? _fechaCaducidad;
    _packaging = widget.draft?.packaging != null
        ? PresentacionCompra.leer(widget.draft!.packaging!)
        : (widget.product?.packaging ?? PresentacionCompra.pieza);
    _codeController = TextEditingController(text: widget.draft?.code ?? widget.product?.code ?? '');
    _contentController = TextEditingController(
      text: formatearCantidad(widget.draft?.packageContent ?? widget.product?.packageContent ?? 1),
    );

    _nameController = TextEditingController(text: _name);
    _precioController = TextEditingController(
      text: widget.draft?.price != null
          ? widget.draft!.price!.toStringAsFixed(2)
          : (widget.product?.price?.toStringAsFixed(2) ?? ''),
    );
    _minimumController = TextEditingController(
      text: _formatearNumero(_minimum),
    );
    _quantityController = TextEditingController(
      text: _formatearNumero(_quantity),
    );
    _dateController = TextEditingController(
      text:
          '${_fechaCaducidad.day.toString().padLeft(2, '0')}/${_fechaCaducidad.month.toString().padLeft(2, '0')}/${_fechaCaducidad.year}',
    );
    _ultimaTiendaId = widget.draft?.ultimaTiendaId;
    _cargarIniciales();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _precioController.dispose();
    _dateController.dispose();
    _minimumController.dispose();
    _quantityController.dispose();
    _codeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _aplicarDatosCodigoBarras(DatosEscaneoProducto datos) {
    setState(() {
      if (!widget.isEditing || _name.trim().isEmpty) {
        if (datos.nombre != null && datos.nombre!.isNotEmpty) {
          _name = datos.nombre!;
          _nameController.text = _name;
        }
      }
      if (!widget.isEditing) {
        if (datos.categoria != null) _category = datos.categoria!;
        if (datos.presentacion != null) _packaging = datos.presentacion!;
        if (datos.contenidoEnvase != null) {
          _contentController.text = formatearCantidad(datos.contenidoEnvase!);
        } else if (!_packaging.esEnvase) {
          _contentController.text = '1';
        }
        if (datos.unidad != null) _unit = datos.unidad!;
      }
      if (datos.precioSugerido != null && datos.precioSugerido! > 0) {
        if (!widget.isEditing || _precioController.text.trim().isEmpty) {
          _precioController.text = datos.precioSugerido!.toStringAsFixed(2);
        }
      }
    });
  }

  void _incrementarMinimo() {
    final parsed =
        leerCantidad(_minimumController.text, permiteCero: true) ?? _minimum;
    final nuevo = parsed + 1.0;
    setState(() {
      _minimum = nuevo;
      _minimumController.text = _formatearNumero(nuevo);
    });
  }

  void _decrementarMinimo() {
    final parsed =
        leerCantidad(_minimumController.text, permiteCero: true) ?? _minimum;
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
    final parsed =
        leerCantidad(_quantityController.text, permiteCero: true) ?? _quantity;
    final nuevo = parsed + 1.0;
    setState(() {
      _quantity = nuevo;
      _quantityController.text = _formatearNumero(nuevo);
    });
  }

  void _decrementarCantidad() {
    final parsed =
        leerCantidad(_quantityController.text, permiteCero: true) ?? _quantity;
    if (parsed > 1.0) {
      final nuevo = parsed - 1.0;
      setState(() {
        _quantity = nuevo;
        _quantityController.text = _formatearNumero(nuevo);
      });
    } else if (parsed > 0.0) {
      final nuevo = (parsed - (_packaging.esEnvase ? 1 : 0.5)).clamp(
        0.0,
        double.infinity,
      );
      setState(() {
        _quantity = nuevo;
        _quantityController.text = _formatearNumero(nuevo);
      });
    }
  }

  Future<void> _cargarIniciales() async {
    try {
      final cats = await _categoriaDao.obtenerTodas();
      final tiendas = await TiendaDao().obtenerTodas();
      final productId = widget.product?.id;
      final producto = productId == null
          ? null
          : await _productoDao.obtenerPorId(productId);
      if (widget.isEditing && producto == null) {
        throw StateError('Producto no encontrado');
      }
      final lotes = productId == null
          ? <Lote>[]
          : await _loteDao.obtenerLotesPorProducto(productId);
      if (!mounted) return;
      setState(() {
        _categoriasBD = cats;
        _tiendas = tiendas;
        _lotesEdicion = lotes.where((l) => l.cantidad > 0).toList();
        _versionLotes++;
        if (producto != null) {
          _name = producto.nombre;
          _nameController.text = _name;
          _codeController.text = producto.codigo ?? '';
          _packaging = PresentacionCompra.leer(producto.presentacion);
          _contentController.text = formatearCantidad(producto.contenidoEnvase);
          final precioBase = producto.precio;
          final contenido = leerCantidad(_contentController.text) ?? 1;
          _precioController.text = precioBase == null
              ? ''
              : (precioBase * (_packaging.esEnvase ? contenido : 1))
                    .toStringAsFixed(2);
          _category = producto.categoriaNombre ?? _category;
          _unit = producto.unidadMedida == 'lt' ? 'L' : producto.unidadMedida;
          _zone = producto.zonaAlmacenamiento ?? _zone;
          if (widget.initialImagePath == null && widget.draft?.imagePath == null) {
            _imagen = producto.imagen.isEmpty ? null : producto.imagen;
          }
          _minimum = producto.stockMinimo;
          _minimumController.text = formatearCantidad(_minimum);
          _ultimaTiendaId = producto.ultimaTiendaId;
        }
        _cargando = false;
        _errorCarga = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          if (widget.isEditing) {
            _errorCarga = 'No se pudieron cargar los datos del producto.';
          }
        });
      }
    }
  }

  String _formatearFechaIso(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _seleccionarFecha() async {
    if (_eligiendoFecha) return;
    _eligiendoFecha = true;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCaducidad,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    _eligiendoFecha = false;
    if (picked != null && mounted) {
      setState(() {
        _fechaCaducidad = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _guardarBorradorActual() async {
    try {
      _borradorActivo = true;
      final parsedMin = double.tryParse(_minimumController.text) ?? _minimum;
      final parsedQty = double.tryParse(_quantityController.text) ?? _quantity;
      final parsedContent = double.tryParse(_contentController.text);
      final parsedPrice = double.tryParse(_precioController.text);

      await ProductFormDraft.guardar(
        ProductFormDraft(
          name: _nameController.text,
          category: _category,
          zone: _zone,
          unit: _unit,
          minimum: parsedMin,
          quantity: parsedQty,
          fechaCaducidad: _fechaCaducidad,
          imagePath: _imagen,
          productId: widget.product?.id ?? widget.draft?.productId,
          code: _codeController.text,
          packaging: _packaging.name,
          packageContent: parsedContent,
          price: parsedPrice,
          ultimaTiendaId: _ultimaTiendaId,
        ),
      );
    } catch (_) {}
  }

  Future<void> _limpiarBorradorSiExiste() async {
    if (_borradorActivo || widget.draft != null) {
      _borradorActivo = false;
      await ProductFormDraft.limpiar();
    }
  }

  Future<void> _guardar() async {
    if (_guardando || _cargando || _errorCarga != null) return;
    final content = leerCantidad(_contentController.text);
    if (_packaging.esEnvase && content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el contenido de cada envase.')),
      );
      return;
    }
    if (!_lotesValidos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa las cantidades de los lotes.')),
      );
      return;
    }
    final parsedMin = leerCantidad(_minimumController.text);
    final cantidadCapturada = leerCantidad(
      _quantityController.text,
      permiteCero: true,
    );
    final parsedQty = cantidadCapturada == null
        ? null
        : normalizarCantidad(
            cantidadCapturada * (_packaging.esEnvase ? content ?? 1 : 1),
          );
    if (parsedMin == null ||
        (!widget.isEditing &&
            !widget.catalogOnly &&
            (parsedQty == null ||
                !cantidadValida(parsedQty, permiteCero: true) ||
                (_packaging.esEnvase &&
                    cantidadCapturada !=
                        cantidadCapturada?.truncateToDouble())))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escribe cantidades válidas de hasta 999999, con máximo tres decimales. El mínimo debe ser mayor que cero.',
          ),
        ),
      );
      return;
    }

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

    final textoPrecio = _precioController.text.trim();
    final precioCentavos = leerPrecioCentavos(textoPrecio);
    if (textoPrecio.isNotEmpty && precioCentavos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un precio válido mayor o igual a 0'),
        ),
      );
      return;
    }
    final precio = precioCentavos == null
        ? null
        : precioCentavos / 100 / (_packaging.esEnvase ? content! : 1);

    setState(() => _guardando = true);

    try {
      final code = _codeController.text.trim();
      if (code.isNotEmpty) {
        final existing = await _productoDao.obtenerPorCodigo(code);
        if (existing != null && existing.id != widget.product?.id) {
          throw StateError('Ese código ya pertenece a ${existing.nombre}.');
        }
      }
      final imagenGuardada = _imagen ?? '';
      int catId = 1;
      final encontrada = _categoriasBD.where(
        (c) => c.nombre.toLowerCase() == _category.toLowerCase(),
      );
      if (encontrada.isNotEmpty) {
        catId = encontrada.first.id!;
      } else {
        catId = await _categoriaDao.insertar(_category);
      }

      final unidadParaBD = _unit.toLowerCase() == 'l'
          ? 'lt'
          : _unit.toLowerCase();

      if (widget.isEditing) {
        final actualizado = Producto(
          id: widget.product!.id,
          nombre: _name.trim(),
          zonaAlmacenamiento: _zone,
          precio: precio,
          codigo: code.isEmpty ? null : code,
          presentacion: _packaging.name,
          contenidoEnvase: _packaging.esEnvase ? content! : 1,
          unidadMedida: unidadParaBD,
          stockMinimo: parsedMin,
          categoriaId: catId,
          ultimaTiendaId: _ultimaTiendaId,
          imagen: imagenGuardada,
        );
        await _productoDao.guardarConLotes(
          actualizado,
          _lotesEdicion
              .map(
                (l) => l.copyWith(
                  presentacion: _packaging,
                  contenidoEnvase: _packaging.esEnvase ? content! : 1,
                ),
              )
              .toList(),
        );
        widget.onSaved?.call(actualizado.id!);

        if (!mounted) return;
        await ShoppingListsPreviewScope.maybeOf(context)?.cargarDesdeBD();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              backgroundColor: PantryColors.green,
            ),
          );
          await _limpiarBorradorSiExiste();
          Navigator.of(context).pop(true);
        }
      } else {
        final nuevoProd = Producto(
          imagen: imagenGuardada,
          ultimaTiendaId: _ultimaTiendaId,
          nombre: _name.trim(),
          zonaAlmacenamiento: _zone,
          precio: precio,
          codigo: code.isEmpty ? null : code,
          presentacion: _packaging.name,
          contenidoEnvase: _packaging.esEnvase ? content! : 1,
          unidadMedida: unidadParaBD,
          stockMinimo: parsedMin,
          categoriaId: catId,
        );
        final nuevoId = await _productoDao.insertar(nuevoProd);

        if (!widget.catalogOnly && (parsedQty ?? 0) > 0) {
          await _loteDao.insertarLote(
            Lote(
              productoId: nuevoId,
              cantidad: parsedQty!,
              fechaCaducidad: _formatearFechaIso(_fechaCaducidad),
              alarmaActiva: _reminder ? 1 : 0,
              horaAviso: _time,
              presentacion: _packaging,
              contenidoEnvase: _packaging.esEnvase ? content! : 1,
            ),
          );
        }

        widget.onSaved?.call(nuevoId);
        if (mounted) {
          String mensaje;
          if (widget.catalogOnly) {
            mensaje = 'Producto agregado al catálogo';
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
          await _limpiarBorradorSiExiste();
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError || e is ArgumentError
                  ? e.toString()
                  : 'No se pudo guardar el producto. Inténtalo de nuevo.',
            ),
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
                        if (_cargando) const LinearProgressIndicator(),
                        if (_errorCarga != null) ...[
                          Text(_errorCarga!),
                          TextButton(
                            onPressed: () {
                              setState(() => _cargando = true);
                              _cargarIniciales();
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                        ProductPhotoSelector(
                          imagePath: _imagen,
                          onImageChanged: (path) =>
                              setState(() => _imagen = path ?? ''),
                          onBeforeCamera: _guardarBorradorActual,
                          onClearDraft: _limpiarBorradorSiExiste,
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
                        CampoCodigoBarras(
                          controller: _codeController,
                          isEditing: widget.isEditing,
                          currentProductId: widget.product?.id ?? widget.draft?.productId,
                          onProductResolved: _aplicarDatosCodigoBarras,
                        ),
                        const SizedBox(height: 18),
                        if (_tiendas.isNotEmpty && !widget.catalogOnly) ...[
                          DropdownButtonFormField<int>(
                            initialValue: _ultimaTiendaId,
                            decoration: const InputDecoration(
                              labelText: 'Última tienda',
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Sin tienda'),
                              ),
                              ..._tiendas.map(
                                (t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.nombre),
                                ),
                              ),
                            ],
                            onChanged: (id) =>
                                setState(() => _ultimaTiendaId = id),
                          ),
                          const SizedBox(height: 18),
                        ],
                        const _ArticleLabel('Categoría', required: true),
                        const SizedBox(height: 9),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in <(String, IconData)>[
                                for (final name in <String>{
                                  ..._categoriasBD.map((c) => c.nombre),
                                  _category,
                                  'Lácteos',
                                  'Granos',
                                  'Enlatados',
                                  'Otros',
                                })
                                  (
                                    name,
                                    name == 'Lácteos'
                                        ? Icons.kitchen_outlined
                                        : name == 'Granos'
                                        ? Icons.grain_rounded
                                        : name == 'Enlatados'
                                        ? Icons.inventory_2_outlined
                                        : Icons.category_outlined,
                                  ),
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
                        ProductPresentationFields(
                          packaging: _packaging,
                          unit: _unit,
                          contentController: _contentController,
                          onPackagingChanged: (p) =>
                              setState(() => _packaging = p),
                          onUnitChanged: (unit) => setState(() => _unit = unit),
                          onContentChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),
                        if (!widget.catalogOnly || widget.isEditing) ...[
                          _ArticleLabel(
                            'Precio de referencia por ${_packaging.esEnvase ? _packaging.singular.toLowerCase() : unidadVisible(_unit)}',
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _precioController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _articleInput().copyWith(
                              prefixText: '\$ ',
                              hintText: 'Ej. 25 o 25.50',
                              helperText:
                                  'Opcional. Puedes usar punto o coma decimal.',
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        const _ArticleLabel('Stock mínimo', required: true),
                        const SizedBox(height: 10),
                        _QuantityControl(
                          controller: _minimumController,
                          onDecrease: _decrementarMinimo,
                          onIncrease: _incrementarMinimo,
                          onChanged: (val) => setState(() => _minimum = val),
                          label: 'stock mínimo',
                          unit: unidadVisible(_unit),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Expresado en ${unidadVisible(_unit)}, igual que las existencias.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: PantryColors.muted,
                          ),
                        ),
                        if (_minimum <= 0)
                          const Text(
                            'Ingresa un valor mayor a 0',
                            style: TextStyle(
                              fontSize: 10,
                              color: PantryColors.red,
                            ),
                          ),
                        const SizedBox(height: 22),
                        if (!widget.isEditing && !widget.catalogOnly)
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
                                  unit: _packaging.esEnvase
                                      ? _packaging.plural
                                      : _unit,
                                  onDecrease: _decrementarCantidad,
                                  onIncrease: _incrementarCantidad,
                                  onChanged: (val) =>
                                      setState(() => _quantity = val),
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
                        if (widget.isEditing &&
                            !widget.catalogOnly &&
                            !_cargando &&
                            _errorCarga == null)
                          ProductLotsEditor(
                            key: ValueKey(_versionLotes),
                            productoId: widget.product!.id!,
                            lotes: _lotesEdicion,
                            unit: _unit,
                            onChanged: (lotes) => setState(() {
                              _lotesValidos = lotes != null;
                              if (lotes != null) _lotesEdicion = lotes;
                            }),
                            defaultPackaging: _packaging,
                            defaultContent:
                                leerCantidad(_contentController.text) ?? 1,
                          ),
                        if (widget.isEditing &&
                            !widget.catalogOnly &&
                            !_cargando &&
                            _errorCarga == null) ...[
                          const SizedBox(height: 16),
                          ProductMovementHistory(
                            productoId: widget.product!.id!,
                            unit: _unit,
                          ),
                        ],
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
                          onPressed:
                              _guardando ||
                                  _cargando ||
                                  _errorCarga != null ||
                                  !_lotesValidos
                              ? null
                              : _guardar,
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
                  key: ValueKey('quantity-$label'),
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PantryColors.ink,
                  ),
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) =>
                          RegExp(r'^\d*(?:[.,]\d{0,3})?$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue,
                    ),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (text) {
                    final valor = leerCantidad(text, permiteCero: true) ?? 0.0;
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
